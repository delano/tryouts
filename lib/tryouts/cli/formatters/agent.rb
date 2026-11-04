# lib/tryouts/cli/formatters/agent.rb
#
# frozen_string_literal: true

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
        @budget          = TokenBudget.new(options[:agent_limit] || TokenBudget::DEFAULT_LIMIT)
        @focus_mode      = options[:agent_focus] || :failures
        # Per-file data, keyed by the file's path. Under --parallel several
        # files report at once, so every event names the file it belongs to.
        @files           = {}
        @files_lock      = Mutex.new
        @total_stats     = { files: 0, tests: 0, failures: 0, errors: 0, not_run: 0, elapsed_time: 0 }
        @output_rendered = false
        @options         = options # Store all options for execution context display
        @all_warnings    = [] # Store warnings globally for execution details
        @errors          = [] # Errors reported during the run (setup, interlude, teardown, file)

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

      def file_parsed(file_path, test_count:, **)
        file_data(file_path)[:tests] = test_count
      end

      def parser_warnings(file_path, warnings:)
        return if warnings.empty? || !@options.fetch(:warnings, true)

        warnings.each do |warning|
          @all_warnings << {
            type: warning.type.to_s,
            message: warning.message,
            line: warning.line_number,
            suggestion: warning.suggestion,
            file: relative_path(file_path)
          }
        end
      end

      # Section failures are listed with the file here, and their messages
      # under Errors:
      def file_result(file_path, total_tests:, failed_count:, error_count:, section_failures: [], not_run: 0, **)
        data                    = file_data(file_path)
        data[:passed]           = total_tests - failed_count - error_count
        data[:not_run]          = not_run
        data[:section_failures] = section_failures
      end

      # Test-level operations - collect failure data
      def test_result(result_packet)
        return if result_packet.passed?

        data  = file_data(result_packet.test_case.path)
        # Summary mode only counts failures, so it skips the details
        entry = @focus_mode == :summary ? { basic: true } : build_failure_data(result_packet)
        (result_packet.error? ? data[:errors] : data[:failures]) << entry

        # Mark truncation for first-failure mode (handle limiting in render phase)
        if first_failure_mode? && (data[:failures].size + data[:errors].size) > 1
          data[:truncated] = true
        end
      end

      # Summary operations - reliable trigger for rendering
      def batch_summary(failure_collector)
        # NOTE: We don't render here because test_runner.rb calls grand_total directly
        # with accurate counts from the TestResultAggregator
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:, not_run: 0)
        return if @output_rendered  # Prevent double rendering

        # Use the accurate counts from TestResultAggregator (passed as parameters)
        # NOT the parsed counts we accumulated in file_parsed()
        @total_stats.merge!(
          tests: total_tests,           # Actual executed test count from aggregator
          failures: failed_count,       # Actual failures from aggregator
          errors: error_count,          # Actual errors from aggregator
          not_run: not_run,             # Tests never reached after a setup or interlude failure
          successful_files: successful_files,
          total_files: total_files,
          elapsed_time: elapsed_time,
        )

        # Now render all collected data
        render_agent_output
        @output_rendered = true
      end

      def error_message(message, backtrace: nil)
        # Store errors for display in execution details
        @errors << {
          message: message,
          backtrace: backtrace
        }
      end

      # Under --parallel errors from several files arrive interleaved, so
      # each is listed with its file
      def file_error_message(file_path, message, backtrace: nil)
        error_message("#{file_data(file_path)[:path]}: #{message}", backtrace: backtrace)
      end

      # A file that failed to parse or load gets a section of its own, and
      # counts as a file failure
      def file_failure(file_path, message, backtrace: nil)
        data = file_data(file_path)
        data[:section_failures] |= [:file_processing]
        error_message("#{data[:path]}: #{message}", backtrace: backtrace)
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
          line: result_packet.failure_line + 1,
          test: test_case.description.to_s.empty? ? 'unnamed test' : test_case.description.to_s
        }

        case result_packet.status
        when :error
          error = result_packet.error
          failure_data[:error] = error ? "#{error.class.name}: #{error.message}" : 'unknown error'
        when :failed
          if !result_packet.expected_results.empty? && !result_packet.actual_results.empty?
            failed_expected   = result_packet.failed_expected
            failed_actual     = result_packet.failed_actual
            expectation_error = FailureCollector.expectation_error(failed_expected, test_case.path)

            if expectation_error
              failure_data[:reason] = @budget.smart_truncate(expectation_error, max_tokens: 50)
            else
              failure_data[:expected] = truncate_value(failed_expected)
              failure_data[:got]      = truncate_value(failed_actual)

              # Add diff for strings if budget allows
              if failed_expected.is_a?(String) && failed_actual.is_a?(String) && @budget.has_budget?
                failure_data[:diff] = generate_simple_diff(failed_expected, failed_actual)
              end
            end
          else
            failure_data[:reason] = 'test failed'
          end
        end

        failure_data
      end

      # A string is shown inspected, so "1" and "" are told apart from 1 and nil
      def truncate_value(value)
        @budget.smart_truncate(value.is_a?(String) ? value.inspect : value, max_tokens: 25)
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
        output = ["SUMMARY: #{summary_counts} in #{@total_stats[:files]} files#{time_suffix}"]
        output.concat([failed_files_line].compact)
        output << ""

        files_with_issues = collected_files.select { |f| issues?(f) }
        if files_with_issues.any?
          output << "FILES:"
          files_with_issues.each do |file_data|
            issue_count = file_data[:failures].size + file_data[:errors].size
            details     = section_details(file_data)
            details.unshift("#{issue_count} issue#{'s' if issue_count != 1}") if issue_count > 0
            output <<"  #{file_data[:path]}: #{details.join(', ')}"
          end
        elsif collected_files.any?
          output << "FILES:"
          collected_files.each do |file_data|
            passed_tests = file_data[:passed] || 0
            output << "  #{file_data[:path]}: #{passed_tests} test#{'s' if passed_tests != 1} passed"
          end
        end

        # Add execution context at the end
        output << ""
        output << render_execution_context

        puts output.join("\n")
      end

      # Errors only (exceptions, and setup, interlude and teardown failures);
      # assertion failures are left out.
      def render_critical_only
        critical_files = collected_files.select { |f| f[:errors].any? || f[:section_failures].any? }

        output = []

        if critical_files.empty? && @errors.empty?
          output << "No critical errors found"
          # Add execution context at the end
          output << ""
          output << render_execution_context
          puts output.join("\n")
          return
        end

        # Summary first
        output << "SUMMARY:"
        output << "#{critical_files.size} file#{'s' if critical_files.size != 1} with critical errors#{time_suffix}"
        output << ""

        # Error details
        critical_files.each do |file_data|
          unless @budget.has_budget?
            output << "... (truncated due to token limit)"
            break
          end

          output << "#{file_data[:path]}:"
          output << "  #{section_details(file_data).join(', ')}" if section_details(file_data).any?

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

        # Add execution context at the end
        output << render_execution_context

        puts output.join("\n")
      end

      def render_full_structured
        output = []

        # Summary first
        output << "SUMMARY:"
        output << "#{summary_counts} in #{@total_stats[:files]} files#{time_suffix}"
        output.concat([failed_files_line].compact)
        output << ""

        # Show files with issues only (unless suppressed)
        files_with_issues = collected_files.select { |f| issues?(f) }

        if files_with_issues.any? && !@options[:agent_no_failures]
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

        # Add execution context at the end
        output << render_execution_context

        puts output.join("\n")
      end

      # "3 testcases passed, 1 failed, 2 errors, 2 not run", from the
      # aggregator's counts
      def summary_counts
        failed = @total_stats[:failures]
        errors = @total_stats[:errors]
        passed = [@total_stats[:tests] - failed - errors, 0].max

        summary  = "#{passed} testcases passed, #{failed} failed"
        summary += ", #{errors} errors" if errors > 0
        summary += ", #{@total_stats[:not_run]} not run" if @total_stats[:not_run] > 0
        summary
      end

      # "Failed files: 2 of 4 (1 setup failure, 1 teardown failure)", when a
      # file failed; a file can fail through its setup, an interlude or its
      # teardown with every test that ran passing. A file that failed to parse
      # or load is a file failure.
      def failed_files_line
        total  = @total_stats[:total_files].to_i
        failed = total - @total_stats[:successful_files].to_i
        return nil unless failed > 0

        kinds  = collected_files.flat_map { |f| f[:section_failures] }.tally
        causes = kinds.map do |kind, count|
          name = { orphan: 'interlude', file_processing: 'file' }.fetch(kind, kind.to_s)
          "#{count} #{name} failure#{'s' if count != 1}"
        end

        line = "Failed files: #{failed} of #{total}"
        causes.empty? ? line : "#{line} (#{causes.join(', ')})"
      end

      # ["2 not run", "interlude failed"] for one file, in the order the
      # other formatters use
      def section_details(file_data)
        details = file_data[:not_run] > 0 ? ["#{file_data[:not_run]} not run"] : []
        details.concat(section_failure_details(file_data[:section_failures]))
      end

      def time_suffix
        elapsed = @total_stats[:elapsed_time]
        elapsed < 2.0 ? " (#{(elapsed * 1000).round}ms)" : " (#{elapsed.round(2)}s)"
      end

      def render_file_section(file_data)
        lines = []

        # File header
        lines << "#{file_data[:path]}:"

        # Setup, interlude or teardown failures, and tests that never ran
        lines << "  #{section_details(file_data).join(', ')}" if section_details(file_data).any?

        # For first-failure mode, only show first error or failure
        if first_failure_mode?
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
        context_lines << "CONTEXT:"

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

        # Files given to the run, including any that failed to parse
        context_lines << "  files_under_test: #{@total_stats[:files]}" if @total_stats[:files] > 0

        # Add errors reported during the run (syntax, setup, interlude, teardown)
        if @errors.any?
          context_lines << ""
          context_lines << "Errors:"
          @errors.each do |error|
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

        # Add framework tips if requested
        if @options[:agent_tips]
          context_lines << ""
          context_lines << render_framework_tips
        end

        # Add re-run command if requested and there are failures
        if @options[:agent_command] && has_failures?
          context_lines << ""
          context_lines << render_rerun_command
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
        # Kernel's methods are called on Kernel: a test file's top-level
        # include can give every object a method of the same name.
        return {} unless File.directory?('.git') || Kernel.system('git rev-parse --git-dir >/dev/null 2>&1')

        require 'timeout'

        Timeout.timeout(2) do
          branch = IO.popen(%w[git rev-parse --abbrev-ref HEAD], err: File::NULL, &:read).strip
          commit = IO.popen(%w[git rev-parse --short HEAD], err: File::NULL, &:read).strip

          # Validate output to prevent injection
          branch = nil unless branch =~ /\A[\w\-\/\.]+\z/
          commit = nil unless commit =~ /\A[a-f0-9]+\z/i

          { branch: branch, commit: commit }
        end
      rescue Timeout::Error, StandardError
        # Return empty hash on any error (timeout, permission, etc.)
        {}
      end

      # Render framework tips and reminders for LLM context
      def render_framework_tips
        tips = []
        tips << "Framework Tips:"
        tips << "  • A file runs top to bottom as one Ruby script; in shared context (default) local and instance variables persist across setup, testcases and teardown"
        tips << "  • Fresh context (--no-shared-context): each testcase gets a new object; setup and the code between earlier testcases re-run before it, teardown after it"
        tips << "  • Only ## starts a description (consecutive ## lines join); a single # line is a plain comment"
        tips << "  • An expectation checks the statement directly above it, or the one it trails (1 + 1 #=> 2); a testcase can have several"
        tips << "  • Expectations run in the test's binding and can use its locals, plus result/_ (the value), error (exception or nil) and elapsed_ms"
        tips << "  • Exception testing: #=!> ErrorClass or #=!> expr; the code runs once and the expectation fails if nothing was raised"
        tips << "  • In a testcase that raised, result is the exception and #=~> matches its message"
        tips.join("\n")
      end

      # Render copy-paste command for re-running failures with verbose-fails-stack
      def render_rerun_command
        files_with_issues = collected_files.select { |f| issues?(f) }
        return "" if files_with_issues.empty?

        cmd = []
        cmd << "Re-run Command (verbose-fails-stack):"

        # Build command parts
        base_cmd = @options[:original_command]&.first || "try"
        file_paths = files_with_issues.map { |f| f[:path] }.join(" ")

        cmd << "  #{base_cmd} -vfs #{file_paths}"
        cmd.join("\n")
      end

      # Check if there are any failures or errors
      def has_failures?
        collected_files.any? { |f| issues?(f) }
      end

      # The data collected for one file, created on its first event
      def file_data(file_path)
        @files_lock.synchronize do
          @files[file_path] ||= {
            path: relative_path(file_path),
            tests: 0,
            passed: nil,
            not_run: 0,
            section_failures: [],
            failures: [],
            errors: [],
          }
        end
      end

      def collected_files
        @files_lock.synchronize { @files.values }
      end

      # A failing or erroring test, a failed setup, interlude or teardown,
      # or tests that never ran
      def issues?(file_data)
        file_data[:failures].any? || file_data[:errors].any? ||
          file_data[:section_failures].any? || file_data[:not_run] > 0
      end

      def first_failure_mode?
        [:first_failure, :'first-failure'].include?(@focus_mode)
      end
    end
  end
end
