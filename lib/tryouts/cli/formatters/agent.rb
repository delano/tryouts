# lib/tryouts/cli/formatters/agent.rb

require_relative 'token_budget'

class Tryouts
  class CLI
    # Agent-optimized formatter designed for LLM context management
    # Features:
    # - Token budget awareness
    # - Structured YAML-like output
    # - No redundant file paths
    # - Smart truncation
    # - Hierarchical organization
    class AgentFormatter
      include FormatterInterface

      def initialize(options = {})
        super
        @budget = TokenBudget.new(options[:agent_limit] || TokenBudget::DEFAULT_LIMIT)
        @focus_mode = options[:agent_focus] || :failures
        @collected_files = []
        @current_file_data = nil
        @total_stats = { files: 0, tests: 0, failures: 0, errors: 0, elapsed: 0 }
        @output_rendered = false

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
          passed: 0
        }
      end

      def file_end(file_path, context_info: {})
        # Finalize current file data
        if @current_file_data
          @collected_files << @current_file_data
          @current_file_data = nil
        end

        # If this is the end of all file processing (single file case) and we haven't output yet
        if @total_stats[:files] <= 1 && !@output_rendered
          # Render output now - this handles the single file case where batch_summary is not called
          # Count failures manually from collected file data since file_result may not be called
          total_tests = @total_stats[:tests]
          failed_count = @collected_files.sum { |f| f[:failures].size }
          error_count = @collected_files.sum { |f| f[:errors].size }
          elapsed_time = @total_stats[:elapsed]

          grand_total(
            total_tests: total_tests,
            failed_count: failed_count,
            error_count: error_count,
            successful_files: @collected_files.size - @collected_files.count { |f| f[:failures].any? || f[:errors].any? },
            total_files: @collected_files.size,
            elapsed_time: elapsed_time
          )
        end
      end

      def file_parsed(_file_path, test_count:, setup_present: false, teardown_present: false)
        @current_file_data[:tests] = test_count if @current_file_data
        @total_stats[:tests] += test_count
      end

      def file_result(_file_path, total_tests:, failed_count:, error_count:, elapsed_time: nil)
        return unless @current_file_data


        @current_file_data[:passed] = total_tests - failed_count - error_count
        @total_stats[:failures] += failed_count
        @total_stats[:errors] += error_count
        @total_stats[:elapsed] += elapsed_time if elapsed_time
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

      # Summary operations - if we get batch_summary, we should render now
      def batch_summary(failure_collector)
        # ALWAYS render output at batch summary time (this is the end for single files)
        if !@output_rendered
          # Simulate grand_total call with current data
          # Count failures manually from collected file data
          total_tests = @total_stats[:tests]
          failed_count = @collected_files.sum { |f| f[:failures].size }
          error_count = @collected_files.sum { |f| f[:errors].size }
          elapsed_time = @total_stats[:elapsed]

          grand_total(
            total_tests: total_tests,
            failed_count: failed_count,
            error_count: error_count,
            successful_files: @collected_files.size - @collected_files.count { |f| f[:failures].any? || f[:errors].any? },
            total_files: @collected_files.size,
            elapsed_time: elapsed_time
          )
        end
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:)
        return if @output_rendered  # Prevent double rendering

        @total_stats.merge!(
          tests: total_tests,
          failures: failed_count,
          errors: error_count,
          successful_files: successful_files,
          total_files: total_files,
          elapsed: elapsed_time
        )

        # Now render all collected data
        render_agent_output
        @output_rendered = true
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

        # Count failures manually from collected file data (same as other render methods)
        failed_count = @collected_files.sum { |f| f[:failures].size }
        error_count = @collected_files.sum { |f| f[:errors].size }
        issues_count = failed_count + error_count
        passed_count = [@total_stats[:tests] - issues_count, 0].max

        if issues_count > 0
          status = "FAIL: #{issues_count}/#{@total_stats[:tests]} tests"
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          status += " (#{details.join(', ')}, #{passed_count} passed)"
        else
          status = "PASS: #{@total_stats[:tests]} tests passed"
        end

        status += " (#{format_time(@total_stats[:elapsed])})" if @total_stats[:elapsed]

        output << status

        # Show which files had failures
        files_with_issues = @collected_files.select { |f| f[:failures].any? || f[:errors].any? }
        if files_with_issues.any?
          output << ""
          output << "Files with issues:"
          files_with_issues.each do |file_data|
            issue_count = file_data[:failures].size + file_data[:errors].size
            output << "  #{file_data[:path]}: #{issue_count} issue#{'s' if issue_count != 1}"
          end
        end

        puts output.join("\n")
      end

      def render_critical_only
        # Only show errors (exceptions), skip assertion failures
        critical_files = @collected_files.select { |f| f[:errors].any? }

        if critical_files.empty?
          puts "No critical errors found"
          return
        end

        output = []
        output << "CRITICAL: #{critical_files.size} file#{'s' if critical_files.size != 1} with errors"
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

        # Header with overall stats
        issues_count = @total_stats[:failures] + @total_stats[:errors]
        passed_count = [@total_stats[:tests] - issues_count, 0].max


        if issues_count > 0
          status_line = "FAIL: #{issues_count}/#{@total_stats[:tests]} tests (#{@total_stats[:files]} files, #{format_time(@total_stats[:elapsed])})"
        else
          status_line = "PASS: #{@total_stats[:tests]} tests (#{@total_stats[:files]} files, #{format_time(@total_stats[:elapsed])})"
        end

        # Always include status line
        output << status_line
        @budget.force_consume(status_line)

        # Only show files with issues (unless focus is different)
        files_to_show = case @focus_mode
        when :failures, :first_failure
          @collected_files.select { |f| f[:failures].any? || f[:errors].any? }
        else
          @collected_files.select { |f| f[:failures].any? || f[:errors].any? }
        end

        if files_to_show.any?
          output << ""
          @budget.consume("\n")

          files_to_show.each do |file_data|
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
        end

        # Final summary line
        summary = "Summary: #{passed_count} passed, #{@total_stats[:failures]} failed"
        summary += ", #{@total_stats[:errors]} errors" if @total_stats[:errors] > 0
        summary += " in #{@total_stats[:files]} files"

        output << ""
        output << summary

        puts output.join("\n")
      end

      def render_file_section(file_data)
        lines = []

        # File header
        lines << "#{file_data[:path]}:"

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
    end
  end
end
