# lib/tryouts/cli/formatters/agent.rb

require_relative 'token_budget'

class Tryouts
  class CLI
    # TOPAZ (Test Output Protocol for AI Zealots) Formatter
    #
    # Language-agnostic test output format designed for LLM context management.
    # This formatter implements the TOPAZ v1.0 specification for structured,
    # token-efficient test result communication.
    #
    # TOPAZ Features:
    # - Language-agnostic field naming (snake_case, hierarchical)
    # - Standardized execution context (runtime, environment, VCS)
    # - Token budget awareness with smart truncation
    # - Cross-platform compatibility (CI/CD, package managers)
    # - Structured failure reporting with diffs
    # - Protocol versioning for forward compatibility
    #
    # Field Specifications:
    # - command: Exact command executed
    # - process_id: System process identifier
    # - runtime: Language, version, platform info
    # - package_manager: Dependency management system
    # - version_control: VCS branch/commit info
    # - environment: Normalized env vars (ci_system, app_env, etc.)
    # - test_framework: Framework name, isolation mode, parser
    # - execution_flags: Runtime flags in normalized form
    # - protocol: TOPAZ version and configuration
    # - project: Auto-detected project type
    # - test_discovery: File pattern matching rules
    #
    # Compatible with: Ruby/RSpec/Minitest, Python/pytest/unittest,
    # JavaScript/Jest/Mocha, Java/JUnit, Go, C#/NUnit, and more.
    #
    # Language Adaptation Examples:
    # Python: runtime.language=python, package_manager.name=pip/poetry/conda
    # Node.js: runtime.language=javascript, package_manager.name=npm/yarn/pnpm
    # Java: runtime.language=java, package_manager.name=maven/gradle
    # Go: runtime.language=go, package_manager.name=go_modules
    # C#: runtime.language=csharp, package_manager.name=nuget/dotnet
    class AgentFormatter
      include FormatterInterface

      def initialize(options = {})
        super
        @budget = TokenBudget.new(options[:agent_limit] || TokenBudget::DEFAULT_LIMIT)
        @focus_mode = options[:agent_focus] || :failures
        @collected_files = []
        @current_file_data = nil
        @total_stats = { files: 0, tests: 0, failures: 0, errors: 0, elapsed_time: 0 }
        @output_rendered = false
        @options = options  # Store all options for execution context display
        @all_warnings = []  # Store warnings globally for execution details
        @syntax_errors = []  # Store syntax errors for execution details

        # No colors in agent mode for cleaner parsing
        @use_colors = false
      end

      # Phase-level output - collect data, don't output immediately
      def phase_header(message, file_count: nil)
        # Store file count for later use, but only store actual file count
        if file_count && message.include?("FILES")
          @total_stats[:files] = file_count
        end
      end

      # File-level operations - start collecting file data
      def file_start(file_path, context_info: {})
        @current_file_data = {
          path: relative_path(file_path),
          tests: 0,
          failures: [],
          errors: [],
          passed: 0,
          context_info: context_info  # Store context info for later display
        }
      end

      def file_end(file_path, context_info: {})
        # Finalize current file data
        if @current_file_data
          @collected_files << @current_file_data
          @current_file_data = nil
        end
        # REMOVED: No longer attempts to render here to avoid premature output
      end

      def file_parsed(_file_path, test_count:, setup_present: false, teardown_present: false)
        if @current_file_data
          @current_file_data[:tests] = test_count
        end
        @total_stats[:tests] += test_count
      end

      def parser_warnings(file_path, warnings:)
        return if warnings.empty? || !@options.fetch(:warnings, true)

        # Store warnings globally for execution details and per-file
        warnings.each do |warning|
          warning_data = {
            type: warning.type.to_s,
            message: warning.message,
            line: warning.line_number,
            suggestion: warning.suggestion,
            file: relative_path(file_path)
          }
          @all_warnings << warning_data
        end

        # Also store in current file data for potential future use
        if @current_file_data
          @current_file_data[:warnings] = @all_warnings.select { |w| w[:file] == relative_path(file_path) }
        end
      end

      def file_result(file_path, total_tests:, failed_count:, error_count:, elapsed_time: nil)
        # Always update global totals
        @total_stats[:failures] += failed_count
        @total_stats[:errors] += error_count
        @total_stats[:elapsed_time] += elapsed_time if elapsed_time

        # Update per-file data - file_result is called AFTER file_end, so data is in @collected_files
        relative_file_path = relative_path(file_path)
        file_data = @collected_files.find { |f| f[:path] == relative_file_path }

        if file_data
          file_data[:passed] = total_tests - failed_count - error_count
          # Also ensure tests count is correct if it wasn't set properly earlier
          file_data[:tests] ||= total_tests
        end
      end


      # Test-level operations - collect failure data
      def test_result(result_packet)
        return unless @current_file_data

        # For summary mode, we still need to collect failures for counting, just don't build detailed data
        if result_packet.failed? || result_packet.error?
          if @focus_mode == :summary
            # Just track counts for summary
            if result_packet.error?
              @current_file_data[:errors] << { basic: true }
            else
              @current_file_data[:failures] << { basic: true }
            end
          else
            # Build detailed failure data for other modes
            failure_data = build_failure_data(result_packet)

            if result_packet.error?
              @current_file_data[:errors] << failure_data
            else
              @current_file_data[:failures] << failure_data
            end

            # Mark truncation for first-failure mode (handle limiting in render phase)
            if (@focus_mode == :first_failure || @focus_mode == :'first-failure') &&
               (@current_file_data[:failures].size + @current_file_data[:errors].size) > 1
              @current_file_data[:truncated] = true
            end
          end
        end
      end

      # Summary operations - reliable trigger for rendering
      def batch_summary(failure_collector)
        # This becomes the single, reliable trigger for rendering
        grand_total(
          total_tests: @total_stats[:tests],
          failed_count: @collected_files.sum { |f| f[:failures].size },
          error_count: @collected_files.sum { |f| f[:errors].size },
          successful_files: @collected_files.size - @collected_files.count { |f| f[:failures].any? || f[:errors].any? },
          total_files: @collected_files.size,
          elapsed_time: @total_stats[:elapsed_time]
        ) unless @output_rendered
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:)
        return if @output_rendered  # Prevent double rendering

        @total_stats.merge!(
          tests: total_tests,
          failures: failed_count,
          errors: error_count,
          successful_files: successful_files,
          total_files: total_files,
          elapsed_time: elapsed_time,
        )

        # Now render all collected data
        render_agent_output
        @output_rendered = true
      end

      def error_message(message, backtrace: nil)
        # Store syntax errors for display in execution details
        @syntax_errors << {
          message: message,
          backtrace: backtrace
        }
      end

      # Override live status - not needed for agent mode
      def live_status_capabilities
        {
          supports_coordination: false,
          output_frequency: :none,
          requires_tty: false
        }
      end

      private

      def build_failure_data(result_packet)
        test_case = result_packet.test_case

        failure_data = {
          line: (test_case.first_expectation_line || test_case.line_range&.first || 0) + 1,
          test: test_case.description.to_s.empty? ? 'unnamed test' : test_case.description.to_s
        }

        case result_packet.status
        when :error
          error = result_packet.error
          failure_data[:error] = error ? "#{error.class.name}: #{error.message}" : 'unknown error'
        when :failed
          if result_packet.expected_results.any? && result_packet.actual_results.any?
            expected = @budget.smart_truncate(result_packet.first_expected, max_tokens: 25)
            actual = @budget.smart_truncate(result_packet.first_actual, max_tokens: 25)
            failure_data[:expected] = expected
            failure_data[:got] = actual

            # Add diff for strings if budget allows
            if result_packet.first_expected.is_a?(String) &&
               result_packet.first_actual.is_a?(String) &&
               @budget.has_budget?
              failure_data[:diff] = generate_simple_diff(result_packet.first_expected, result_packet.first_actual)
            end
          else
            failure_data[:reason] = 'test failed'
          end
        end

        failure_data
      end

      def generate_simple_diff(expected, actual)
        return nil unless @budget.remaining > 100  # Only if we have decent budget left

        # Simple line-by-line diff
        exp_lines = expected.split("\n")
        act_lines = actual.split("\n")

        diff_lines = []
        diff_lines << "- #{act_lines.first}" if act_lines.any?
        diff_lines << "+ #{exp_lines.first}" if exp_lines.any?

        diff_result = diff_lines.join("\n")
        return @budget.fit_text(diff_result) if @budget.would_exceed?(diff_result)
        diff_result
      end

      def render_agent_output
        case @focus_mode
        when :summary
          render_summary_only
        when :critical
          render_critical_only
        else
          render_full_structured
        end
      end

      def render_summary_only
        output = []

        time_str = if @total_stats[:elapsed_time] < 2.0
          " (#{(@total_stats[:elapsed_time] * 1000).round}ms)"
        else
          " (#{@total_stats[:elapsed_time].round(2)}s)"
        end

        # Add execution context header for agent clarity
        output << render_execution_context
        output << ""

        # Count failures manually from collected file data (same as other render methods)
        failed_count = @collected_files.sum { |f| f[:failures].size }
        error_count = @collected_files.sum { |f| f[:errors].size }
        issues_count = failed_count + error_count
        passed_count = [@total_stats[:tests] - issues_count, 0].max

        status_parts = []
        if issues_count > 0
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          status_parts << "FAIL: #{issues_count}/#{@total_stats[:tests]} tests (#{details.join(', ')}, #{passed_count} passed#{time_str})"
        else
          # Agent doesn't need output in the positive case (i.e. for passing
          # tests). It just fills out the context window.
        end

        status_parts << "(#{format_time(@total_stats[:elapsed_time])})" if @total_stats[:elapsed_time]

        output << status_parts.join(" ")

        # Always show file information for agent context
        output << ""

        files_with_issues = @collected_files.select { |f| f[:failures].any? || f[:errors].any? }
        if files_with_issues.any?
          output << "Files:"
          files_with_issues.each do |file_data|
            issue_count = file_data[:failures].size + file_data[:errors].size
            output << "  #{file_data[:path]}: #{issue_count} issue#{'s' if issue_count != 1}"
          end
        elsif @collected_files.any?
          # Show files that were processed successfully
          output << "Files:"
          @collected_files.each do |file_data|
            # Use the passed count from file_result if available, otherwise calculate
            passed_tests = file_data[:passed] ||
                          ((file_data[:tests] || 0) - file_data[:failures].size - file_data[:errors].size)
            output << "  #{file_data[:path]}: #{passed_tests} test#{'s' if passed_tests != 1} passed"
          end
        end

        puts output.join("\n") if output.any?
      end

      def render_critical_only
        # Only show errors (exceptions), skip assertion failures
        critical_files = @collected_files.select { |f| f[:errors].any? }

        time_str = if @total_stats[:elapsed_time] < 2.0
          " (#{(@total_stats[:elapsed_time] * 1000).round}ms)"
        else
          " (#{@total_stats[:elapsed_time].round(2)}s)"
        end

        output = []

        # Add execution context header for agent clarity
        output << render_execution_context
        output << ""

        if critical_files.empty?
          output << "No critical errors found"
          puts output.join("\n")
          return
        end

        output << "CRITICAL: #{critical_files.size} file#{'s' if critical_files.size != 1} with errors#{time_str}"
        output << ""

        critical_files.each do |file_data|
          unless @budget.has_budget?
            output << "... (truncated due to token limit)"
            break
          end

          output << "#{file_data[:path]}:"

          file_data[:errors].each do |error|
            error_line = "  L#{error[:line]}: #{error[:error]}"
            if @budget.would_exceed?(error_line)
              output << @budget.fit_text(error_line)
            else
              output << error_line
              @budget.consume(error_line)
            end
          end

          output << ""
        end

        puts output.join("\n")
      end

      def render_full_structured
        output = []

        time_str = if @total_stats[:elapsed_time] < 2.0
          " (#{(@total_stats[:elapsed_time] * 1000).round}ms)"
        else
          " (#{@total_stats[:elapsed_time].round(2)}s)"
        end

        # Add execution context header for agent clarity
        output << render_execution_context
        output << ""

        # Count actual failures from collected data
        failed_count = @collected_files.sum { |f| f[:failures].size }
        error_count = @collected_files.sum { |f| f[:errors].size }
        issues_count = failed_count + error_count
        passed_count = [@total_stats[:tests] - issues_count, 0].max

        # Show files with issues only
        files_with_issues = @collected_files.select { |f| f[:failures].any? || f[:errors].any? }

        if files_with_issues.any?
          files_with_issues.each do |file_data|
            break unless @budget.has_budget?

            file_section = render_file_section(file_data)
            if @budget.would_exceed?(file_section)
              # Try to fit what we can
              truncated = @budget.fit_text(file_section, preserve_suffix: "\n  ... (truncated)")
              output << truncated if truncated.length > 20  # Only if meaningful content remains
              break
            else
              output << file_section
              @budget.consume(file_section)
            end
          end
          output << ""
        end

        # Final summary line
        summary = "Summary: \n"
        summary += "#{passed_count} testcases passed, #{failed_count} failed"
        summary += ", #{error_count} errors" if error_count > 0
        summary += " in #{@total_stats[:files]} files#{time_str}"

        output << summary

        puts output.join("\n")
      end

      def render_file_section(file_data)
        lines = []

        # File header
        lines << "#{file_data[:path]}:"

        # Check if file has any issues
        has_issues = file_data[:failures].any? || file_data[:errors].any?

        # If no issues, show success summary
        if !has_issues
          # Use the passed count from file_result if available, otherwise calculate
          passed_tests = file_data[:passed] ||
                        ((file_data[:tests] || 0) - file_data[:failures].size - file_data[:errors].size)


          lines << "  ✓ #{passed_tests} test#{'s' if passed_tests != 1} passed"
          return lines.join("\n")
        end

        # For first-failure mode, only show first error or failure
        if @focus_mode == :first_failure || @focus_mode == :'first-failure'
          shown_count = 0

          # Show first error
          if file_data[:errors].any? && shown_count == 0
            error = file_data[:errors].first
            lines << "  L#{error[:line]}: #{error[:error]}"
            lines << "    Test: #{error[:test]}" if error[:test] != 'unnamed test'
            shown_count += 1
          end

          # Show first failure if no error was shown
          if file_data[:failures].any? && shown_count == 0
            failure = file_data[:failures].first
            line_parts = ["  L#{failure[:line]}:"]

            if failure[:expected] && failure[:got]
              line_parts << "expected #{failure[:expected]}, got #{failure[:got]}"
            elsif failure[:reason]
              line_parts << failure[:reason]
            end

            lines << line_parts.join(' ')
            lines << "    Test: #{failure[:test]}" if failure[:test] != 'unnamed test'

            # Add diff if available and budget allows
            if failure[:diff] && @budget.remaining > 50
              lines << "    Diff:"
              failure[:diff].split("\n").each { |diff_line| lines << "      #{diff_line}" }
            end
          end

          # Show truncation notice
          total_issues = file_data[:errors].size + file_data[:failures].size
          if total_issues > 1
            lines << "  ... (#{total_issues - 1} more failures not shown)"
          end
        else
          # Normal mode - show all errors and failures
          # Errors first (more critical)
          file_data[:errors].each do |error|
            next if error[:basic]  # Skip basic entries from summary mode
            lines << "  L#{error[:line]}: #{error[:error]}"
            lines << "    Test: #{error[:test]}" if error[:test] != 'unnamed test'
          end

          # Then failures
          file_data[:failures].each do |failure|
            next if failure[:basic]  # Skip basic entries from summary mode
            line_parts = ["  L#{failure[:line]}:"]

            if failure[:expected] && failure[:got]
              line_parts << "expected #{failure[:expected]}, got #{failure[:got]}"
            elsif failure[:reason]
              line_parts << failure[:reason]
            end

            lines << line_parts.join(' ')
            lines << "    Test: #{failure[:test]}" if failure[:test] != 'unnamed test'

            # Add diff if available and budget allows
            if failure[:diff] && @budget.remaining > 50
              lines << "    Diff:"
              failure[:diff].split("\n").each { |diff_line| lines << "      #{diff_line}" }
            end
          end

          # Show truncation notice if applicable
          if file_data[:truncated]
            lines << "  ... (more failures not shown)"
          end
        end

        lines.join("\n")
      end

      def relative_path(file_path)
        # Remove leading path components to save tokens
        path = Pathname.new(file_path).relative_path_from(Pathname.pwd).to_s
        # If relative path is longer, use just filename
        path.include?('../') ? File.basename(file_path) : path
      rescue
        File.basename(file_path)
      end

      def format_time(seconds)
        return '0ms' unless seconds

        if seconds < 0.001
          "#{(seconds * 1_000_000).round}μs"
        elsif seconds < 1
          "#{(seconds * 1000).round}ms"
        else
          "#{seconds.round(2)}s"
        end
      end

      def render_execution_context
        context_lines = []
        context_lines << "EXECUTION_CONTEXT:"

        # Command that was executed
        if @options[:original_command]
          command_str = @options[:original_command].join(' ')
          context_lines << "  command: #{command_str}"
        end

        # Compact system info on one line when possible
        context_lines << "  pid: #{Process.pid} | pwd: #{Dir.pwd}"

        # Runtime - compact format
        platform = RUBY_PLATFORM.gsub(/darwin\d+/, 'darwin')  # Simplify darwin25 -> darwin
        context_lines << "  runtime: ruby #{RUBY_VERSION} (#{platform}); tryouts #{Tryouts::VERSION}"

        # Package manager - only if present, compact format
        if defined?(Bundler)
          context_lines << "  package_manager: bundler #{Bundler::VERSION}"
        end

        # Version control - compact single line with timeout protection
        git_info = safe_git_info
        if git_info[:branch] && git_info[:commit] && !git_info[:branch].empty? && !git_info[:commit].empty?
          context_lines << "  vcs: git #{git_info[:branch]}@#{git_info[:commit]}"
        end

        # Environment - only non-defaults
        env_vars = build_environment_context
        if env_vars.any?
          # Compact key=value format
          env_str = env_vars.map { |k, v| "#{k}=#{v}" }.join(', ')
          context_lines << "  environment: #{env_str}"
        end

        # Test framework - compact critical info only
        framework = @options[:framework] || :direct
        shared_context = if @options.key?(:shared_context)
          @options[:shared_context]
        else
          # Apply framework defaults
          case framework
          when :rspec, :minitest
            false
          else
            true  # direct/tryouts defaults to shared
          end
        end

        isolation = shared_context ? 'shared' : 'isolated'
        context_lines << "  test_framework: #{framework} (#{isolation})"

        # Execution flags - only if non-standard
        flags = build_execution_flags
        if flags.any?
          context_lines << "  flags: #{flags.join(', ')}"
        end

        # TOPAZ protocol - compact
        context_lines << "  protocol: TOPAZ v0.3 | focus: #{@focus_mode} | limit: #{@budget.limit}"

        # File count being tested
        if @collected_files && @collected_files.any?
          context_lines << "  files_under_test: #{@collected_files.size}"
        elsif @total_stats[:files] && @total_stats[:files] > 0
          context_lines << "  files_under_test: #{@total_stats[:files]}"
        end

        # Add syntax errors if any (these prevent test execution)
        if @syntax_errors.any?
          context_lines << ""
          context_lines << "Syntax Errors:"
          @syntax_errors.each do |error|
            # Clean up the error message to remove redundant prefixes
            clean_message = error[:message].gsub(/^ERROR:\s*/i, '').strip
            context_lines << "  #{clean_message}"
            if error[:backtrace] && @options[:debug]
              error[:backtrace].first(3).each do |trace|
                context_lines << "    #{trace}"
              end
            end
          end
        end

        # Add warnings if any
        if @all_warnings.any? && @options.fetch(:warnings, true)
          context_lines << ""
          context_lines << "Parser Warnings:"
          @all_warnings.each do |warning|
            context_lines << "  #{warning[:file]}:#{warning[:line]}: #{warning[:message]}"
            context_lines << "    #{warning[:suggestion]}" if warning[:suggestion]
          end
        end

        context_lines.join("\n")
      end

      # Build environment context with language-agnostic keys
      def build_environment_context
        env_vars = {}

        # CI/CD detection - prioritize most specific
        if ENV['GITHUB_ACTIONS']
          env_vars['CI'] = 'github'
        elsif ENV['GITLAB_CI']
          env_vars['CI'] = 'gitlab'
        elsif ENV['JENKINS_URL']
          env_vars['CI'] = 'jenkins'
        elsif ENV['CI']
          env_vars['CI'] = 'true'
        end

        # Runtime environment - only if not default
        if ENV['RAILS_ENV'] && ENV['RAILS_ENV'] != 'development'
          env_vars['ENV'] = ENV['RAILS_ENV']
        elsif ENV['RACK_ENV'] && ENV['RACK_ENV'] != 'development'
          env_vars['ENV'] = ENV['RACK_ENV']
        elsif ENV['NODE_ENV'] && ENV['NODE_ENV'] != 'development'
          env_vars['ENV'] = ENV['NODE_ENV']
        end

        # Coverage - simplified
        env_vars['COV'] = '1' if ENV['COVERAGE'] || ENV['SIMPLECOV']

        # Test seed for reproducibility
        env_vars['SEED'] = ENV['SEED'] if ENV['SEED']

        env_vars
      end

      # Build execution flags in language-agnostic format
      def build_execution_flags
        flags = []
        flags << "verbose" if @options[:verbose]
        flags << "fails-only" if @options[:fails_only]
        flags << "debug" if @options[:debug]
        flags << "traces" if @options[:stack_traces] && !@options[:debug]  # debug implies traces
        flags << "parallel" if @options[:parallel]
        flags << "line-spec" if @options[:line_spec]
        flags << "strict" if @options[:strict]
        flags << "quiet" if @options[:quiet]
        flags
      end

      # Get test discovery patterns in language-agnostic format
      def get_test_discovery_patterns
        patterns = []

        # Ruby/Tryouts patterns
        patterns.concat([
          "**/*_try.rb",
          "**/*.try.rb",
          "try/**/*.rb",
          "tryouts/**/*.rb"
        ])

        # TOPA-compatible patterns for other languages:
        # Python: ["**/*_test.py", "**/test_*.py", "tests/**/*.py"]
        # JavaScript: ["**/*.test.js", "**/*.spec.js", "__tests__/**/*.js"]
        # Java: ["**/*Test.java", "**/Test*.java", "src/test/**/*.java"]
        # Go: ["**/*_test.go"]
        # C#: ["**/*Test.cs", "**/*Tests.cs"]
        # PHP: ["**/*Test.php", "tests/**/*.php"]
        # Rust: ["**/*_test.rs", "tests/**/*.rs"]

        patterns
      end

      private

      # Safely get git information with timeout protection
      def safe_git_info
        # Check if we're in a git repository
        return {} unless File.directory?('.git') || system('git rev-parse --git-dir >/dev/null 2>&1')

        require 'timeout'

        Timeout.timeout(2) do
          branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
          commit = `git rev-parse --short HEAD 2>/dev/null`.strip

          # Validate output to prevent injection
          branch = nil unless branch =~ /\A[\w\-\/\.]+\z/
          commit = nil unless commit =~ /\A[a-f0-9]+\z/i

          { branch: branch, commit: commit }
        end
      rescue Timeout::Error, StandardError
        # Return empty hash on any error (timeout, permission, etc.)
        {}
      end
    end
  end
end
