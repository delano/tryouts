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
        @show_trace     = options.fetch(:trace, true)
        @current_indent = 0
      end

      # Phase-level output
      def phase_header(message, file_count = nil)
        separator_line = '=' * @line_width
        header_line    = message.center(@line_width)

        output = [
          '',
          separator_line,
          header_line,
          separator_line,
        ]

        puts output.join("\n")
      end

      # File-level operations
      def file_start(file_path, context_info = {})
        framework = context_info[:framework] || :direct
        context   = context_info[:context] || :fresh

        with_indent(1) do
          puts "Framework: #{framework}"
          puts "Context: #{context}"
        end

        puts file_header_visual(file_path)
      end

      def file_parsed(file_path, test_count, setup_present: false, teardown_present: false)
        pretty_path = Console.pretty_path(file_path)
        message     = "Parsed #{test_count} test cases from #{pretty_path}"

        extras   = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        message += " (#{extras.join(', ')})" unless extras.empty?

        puts indent_text(message, 2)
      end

      def file_execution_start(file_path, test_count, context_mode)
        message = "Running #{test_count} tests with #{context_mode} context"
        puts indent_text(message, 1)
      end

      def file_result(file_path, total_tests, failed_count, elapsed_time)
        status = if failed_count > 0
          Console.color(:red, "✗ #{failed_count}/#{total_tests} tests failed")
        else
          Console.color(:green, "✓ #{total_tests} tests passed")
                 end

        puts indent_text(status, 2)

        if elapsed_time
          time_msg = "Completed in #{elapsed_time.round(3)}s"
          puts indent_text(Console.color(:dim, time_msg), 2)
        end
      end

      # Test-level operations
      def test_start(test_case, index, total)
        desc    = test_case.description.to_s
        desc    = 'Unnamed test' if desc.empty?
        message = "Test #{index}/#{total}: #{desc}"
        puts indent_text(Console.color(:dim, message), 2)
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil)
        should_show = @show_passed || result_status != :passed

        return unless should_show

        status_line = case result_status
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

        location = "#{Console.pretty_path(test_case.path)}:#{test_case.line_range.first + 1}"
        puts indent_text("#{status_line} #{test_case.description} @ #{location}", 2)

        # Show source code for verbose mode
        show_test_source_code(test_case)

        # Show failure details for failed tests
        if [:failed, :error].include?(result_status)
          show_failure_details(test_case, actual_results)
        end
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
      end

      def teardown_output(output_text)
        return if output_text.strip.empty?

        output_text.lines.each do |line|
          puts indent_text(line.chomp, 0)
        end
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time)
        if failed_count > 0
          passed  = total_tests - failed_count
          message = "#{failed_count} failed, #{passed} passed"
          color   = :red
        else
          message = "#{total_tests} tests passed"
          color   = :green
        end

        time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
        summary  = Console.color(color, "#{message}#{time_str}")
        puts summary
      end

      def grand_total(total_tests, failed_count, successful_files, total_files, elapsed_time)
        puts
        puts '=' * @line_width
        puts 'Grand Total:'

        if failed_count > 0
          passed = total_tests - failed_count
          puts "#{failed_count} failed, #{passed} passed (#{elapsed_time.round(2)}s)"
        else
          puts "#{total_tests} tests passed (#{elapsed_time.round(2)}s)"
        end

        puts "Files processed: #{successful_files}/#{total_files} successful"
        puts '=' * @line_width
      end

      # Debug and diagnostic output
      def debug_info(message, level = 0)
        return unless @show_debug

        prefix = Console.color(:cyan, 'INFO ')
        puts indent_text("#{prefix} #{message}", level + 1)
      end

      def trace_info(message, level = 0)
        return unless @show_trace

        prefix = Console.color(:dim, 'TRACE')
        puts indent_text("#{prefix} #{message}", level + 1)
      end

      def error_message(message, details = nil)
        error_msg = Console.color(:red, "ERROR: #{message}")
        puts indent_text(error_msg, 1)

        if details && @show_debug
          puts indent_text("Details: #{details}", 2)
        end
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
        else
          puts '-' * @line_width
        end
      end

      private

      def show_test_source_code(test_case)
        puts indent_text('Source code:', 3)

        # Read the source file and extract the relevant lines
        source_lines = File.readlines(test_case.path)
        start_line   = test_case.line_range.first
        end_line     = test_case.line_range.last

        (start_line..end_line).each do |line_num|
          line_content = source_lines[line_num]&.chomp || ''
          line_display = format('%3d: %s', line_num + 1, line_content)

          # Highlight expectation lines
          if test_case.expectations.any? { |exp| line_content.include?(exp) }
            line_display = Console.color(:yellow, line_display)
          end

          puts indent_text(line_display, 4)
        end
        puts
      end

      def show_failure_details(test_case, actual_results)
        return if actual_results.empty?

        puts indent_text('Expected vs Actual:', 3)

        actual_results.each_with_index do |actual, idx|
          expected_line = test_case.expectations[idx] if test_case.expectations

          if expected_line
            puts indent_text("Expected: #{Console.color(:green, expected_line)}", 4)
            puts indent_text("Actual:   #{Console.color(:red, actual.inspect)}", 4)
          else
            puts indent_text("Actual:   #{Console.color(:red, actual.inspect)}", 4)
          end

          # Show difference if both are strings
          if expected_line && actual.is_a?(String) && expected_line.is_a?(String)
            show_string_diff(expected_line, actual)
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
          '-' * @line_width,
          header_content + padding,
          '-' * @line_width,
        ].join("\n")
      end

      def indent_text(text, level)
        indent = '  ' * level
        "#{indent}#{text}"
      end

      def with_indent(level)
        old_indent      = @current_indent
        @current_indent = level
        yield
      ensure
        @current_indent = old_indent
      end
    end

    # Verbose formatter that only shows failures and errors
    class VerboseFailsFormatter < VerboseFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil)
        # Only show failed/error tests, but with full source code
        return if result_status == :passed

        super
      end
    end
  end
end
