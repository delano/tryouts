# lib/tryouts/cli/formatters/verbose.rb

class Tryouts
  class CLI
    # Detailed formatter with comprehensive output and clear visual hierarchy
    class VerboseFormatter
      include FormatterInterface

      def initialize(options = {})
        @line_width     = options.fetch(:line_width, 70)
        @show_passed    = options.fetch(:show_passed, true)
        @show_debug     = options.fetch(:debug, false)
        @show_trace     = options.fetch(:trace, false)
        @current_indent = 0
      end

      # Phase-level output
      def phase_header(message, _file_count = nil, level = 0)
        return if level.equal?(1)

        separators = [
          { char: '=', width: @line_width },      # Major phases
          { char: '-', width: @line_width - 10 }, # Sub-phases
          { char: '.', width: @line_width - 20 }, # Details
          { char: '~', width: @line_width - 30 }, # Minor items
        ]

        config = separators[level] || separators.last

        separator_line = config[:char] * config[:width]
        header_line    = message.center(config[:width])

        output = case level
        when 0, 1
          [separator_line, header_line, separator_line]
        else
          [header_line, separator_line]
        end

        with_indent(level) do
          puts output.join("\n")
        end
      end

      # File-level operations
      def file_start(file_path, _context_info = {})
        puts file_header_visual(file_path)
      end

      def file_end(_file_path, _context_info = {})
        # No output in verbose mode
      end

      def file_parsed(_file_path, _test_count, setup_present: false, teardown_present: false)
        message = ''

        extras   = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        message += " (#{extras.join(', ')})" unless extras.empty?

        puts indent_text(message, 2)
      end

      def file_execution_start(_file_path, test_count, context_mode)
        message = "Running #{test_count} tests with #{context_mode} context"
        puts indent_text(message, 1)
      end

      # Summary operations
      #
      # Called right before file_result
      def batch_summary(total_tests, failed_count, elapsed_time)
        # No output in verbose mode
      end

      def file_result(_file_path, total_tests, failed_count, error_count, elapsed_time)
        issues_count = failed_count + error_count
        passed_count = total_tests - issues_count
        details      = [
          "#{passed_count} passed",
        ]
        puts
        if issues_count > 0
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          details_str = details.join(', ')
          color       = :red

          time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
          message  = "✗ Out of #{total_tests} tests: #{details_str}#{time_str}"
          puts indent_text(Console.color(color, message), 2)
        else
          message = "#{total_tests} tests passed"
          color   = :green
          puts indent_text(Console.color(color, "✓ #{message}"), 2)
        end

        return unless elapsed_time

        time_msg = "Completed in #{format_timing(elapsed_time).strip.tr('()', '')}"

        puts indent_text(Console.color(:dim, time_msg), 2)
      end

      # Test-level operations
      def test_start(test_case, index, total)
        desc    = test_case.description.to_s
        desc    = 'Unnamed test' if desc.empty?
        message = "Test #{index}/#{total}: #{desc}"
        puts indent_text(Console.color(:dim, message), 2)
      end

      def test_end(_test_case, _index, _total)
        # No output in verbose mode
      end

      def test_result(result_packet)
        should_show = @show_passed || !result_packet.passed?

        return unless should_show

        status_line = case result_packet.status
        when :passed
          Console.color(:green, 'PASSED')
        when :failed
          Console.color(:red, 'FAILED')
        when :error
          Console.color(:red, 'ERROR')
        when :skipped
          Console.color(:yellow, 'SKIPPED')
        else
          'UNKNOWN'
        end

        test_case = result_packet.test_case
        location  = "#{Console.pretty_path(test_case.path)}:#{test_case.first_expectation_line + 1}"
        puts
        puts indent_text("#{status_line} @ #{location}", 2)

        # Show source code for verbose mode
        show_test_source_code(test_case)

        # Show failure details for failed tests
        if result_packet.failed? || result_packet.error?
          show_failure_details(test_case, result_packet.actual_results, result_packet.expected_results)
        # Show exception details for passed exception expectations
        elsif result_packet.passed? && has_exception_expectations?(test_case)
          show_exception_details(test_case, result_packet.actual_results, result_packet.expected_results)
        end
      end

      def test_output(_test_case, output_text)
        return if output_text.nil? || output_text.strip.empty?

        puts indent_text('Test Output:', 3)
        puts indent_text(Console.color(:dim, '--- BEGIN OUTPUT ---'), 3)

        output_text.lines.each do |line|
          puts indent_text(line.chomp, 4)
        end

        puts indent_text(Console.color(:dim, '--- END OUTPUT ---'), 3)
        puts
      end

      # Setup/teardown operations
      def setup_start(line_range)
        message = "Executing global setup (lines #{line_range.first}..#{line_range.last})"
        puts indent_text(Console.color(:cyan, message), 2)
      end

      def setup_output(output_text)
        return if output_text.strip.empty?

        output_text.lines.each do |line|
          puts indent_text(line.chomp, 0)
        end
      end

      def teardown_start(line_range)
        message = "Executing teardown (lines #{line_range.first}..#{line_range.last})"
        puts indent_text(Console.color(:cyan, message), 2)
        puts
      end

      def teardown_output(output_text)
        return if output_text.strip.empty?

        output_text.lines.each do |line|
          puts indent_text(line.chomp, 0)
        end
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
        puts
        puts '=' * @line_width
        puts 'Grand Total:'

        issues_count = failed_count + error_count
        time_str     =
          if elapsed_time < 2.0
            " (#{(elapsed_time * 1000).round}ms)"
          else
            " (#{elapsed_time.round(2)}s)"
          end

        if issues_count > 0
          passed  = [total_tests - issues_count, 0].max  # Ensure passed never goes negative
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          puts "#{details.join(', ')}, #{passed} passed#{time_str}"
        else
          puts "#{total_tests} tests passed#{time_str}"
        end

        puts "Files processed: #{successful_files} of #{total_files} successful"
        puts '=' * @line_width
      end

      # Debug and diagnostic output
      def debug_info(message, level = 0)
        return unless @show_debug

        prefix = Console.color(:cyan, 'INFO ')
        puts
        puts indent_text("#{prefix} #{message}", level + 1)
      end

      def trace_info(message, level = 0)
        return unless @show_trace

        prefix = Console.color(:dim, 'TRACE')
        puts indent_text("#{prefix} #{message}", level + 1)
      end

      def error_message(message, backtrace = nil)
        error_msg = Console.color(:red, "ERROR: #{message}")
        puts indent_text(error_msg, 1)

        return unless backtrace && @show_debug

        puts indent_text('Details:', 2)
        # Show first 10 lines of backtrace to avoid overwhelming output
        backtrace.first(10).each do |line|
          puts indent_text(line, 3)
        end
        puts indent_text("... (#{backtrace.length - 10} more lines)", 3) if backtrace.length > 10
      end

      # Utility methods
      def raw_output(text)
        puts text
      end

      def separator(style = :light)
        case style
        when :heavy
          puts '=' * @line_width
        when :light
          puts '-' * @line_width
        when :dotted
          puts '.' * @line_width
        else # rubocop:disable Lint/DuplicateBranch
          puts '-' * @line_width
        end
      end

      private

      def has_exception_expectations?(test_case)
        test_case.expectations.any? { |exp| exp.type == :exception }
      end

      def show_exception_details(test_case, actual_results, expected_results = [])
        return if actual_results.empty?

        puts indent_text('Exception Details:', 4)

        actual_results.each_with_index do |actual, idx|
          expected    = expected_results[idx] if expected_results && idx < expected_results.length
          expectation = test_case.expectations[idx] if test_case.expectations

          if expectation&.type == :exception
            puts indent_text("Caught: #{Console.color(:blue, actual.inspect)}", 5)
            puts indent_text("Expectation: #{Console.color(:green, expectation.content)}", 5)
            puts indent_text("Result: #{Console.color(:green, expected.inspect)}", 5) if expected
          end
        end
        puts
      end

      def show_test_source_code(test_case)
        # Use pre-captured source lines from parsing
        start_line = test_case.line_range.first

        test_case.source_lines.each_with_index do |line_content, index|
          line_num     = start_line + index
          line_display = format('%3d: %s', line_num + 1, line_content)

          # Highlight expectation lines by checking if this line contains any expectation syntax
          if line_content.match?(%r{^\s*#\s*=(!|<|=|/=|\||:|~|%|\d+)?>\s*})
            line_display = Console.color(:yellow, line_display)
          end

          puts indent_text(line_display, 4)
        end
        puts
      end

      def show_failure_details(test_case, actual_results, expected_results = [])
        return if actual_results.empty?

        actual_results.each_with_index do |actual, idx|
          expected      = expected_results[idx] if expected_results && idx < expected_results.length
          expected_line = test_case.expectations[idx] if test_case.expectations

          if !expected.nil?
            # Use the evaluated expected value from the evaluator
            puts indent_text("Expected: #{Console.color(:green, expected.inspect)}", 4)
            puts indent_text("Actual:   #{Console.color(:red, actual.inspect)}", 4)
          elsif expected_line && !expected_results.empty?
            # Only show raw expectation content if we have expected_results (non-error case)
            puts indent_text("Expected: #{Console.color(:green, expected_line.content)}", 4)
            puts indent_text("Actual:   #{Console.color(:red, actual.inspect)}", 4)
          else
            # For error cases (empty expected_results), just show the error
            puts indent_text("Error:   #{Console.color(:red, actual.inspect)}", 4)
          end

          # Show difference if both are strings
          if !expected.nil? && actual.is_a?(String) && expected.is_a?(String)
            show_string_diff(expected, actual)
          end

          puts
        end
      end

      def show_string_diff(expected, actual)
        return if expected == actual

        puts indent_text('Difference:', 4)
        puts indent_text("- #{Console.color(:red, actual)}", 5)
        puts indent_text("+ #{Console.color(:green, expected)}", 5)
      end

      def file_header_visual(file_path)
        pretty_path    = Console.pretty_path(file_path)
        header_content = ">>>>>  #{pretty_path}  "
        padding_length = [@line_width - header_content.length, 0].max
        padding        = '<' * padding_length

        [
          indent_text('-' * @line_width, 1),
          indent_text(header_content + padding, 1),
          indent_text('-' * @line_width, 1),
        ].join("\n")
      end

      def format_timing(elapsed_time)
        if elapsed_time < 0.001
          " (#{(elapsed_time * 1_000_000).round}μs)"
        elsif elapsed_time < 1
          " (#{(elapsed_time * 1000).round}ms)"
        else
          " (#{elapsed_time.round(2)}s)"
        end
      end
    end

    # Verbose formatter that only shows failures and errors
    class VerboseFailsFormatter < VerboseFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def test_result(result_packet)
        # Only show failed/error tests, but with full source code
        return if result_packet.passed?

        super
      end
    end
  end
end
