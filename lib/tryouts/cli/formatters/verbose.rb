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
        return unless @show_passed || result_status == :failed

        case result_status
        when :passed
          status_line = Console.color(:green, 'PASSED')
        when :failed
          status_line = Console.color(:red, 'FAILED')
          show_failure_details(test_case, actual_results)
        when :skipped
          status_line = Console.color(:yellow, 'SKIPPED')
        else
          status_line = 'UNKNOWN'
        end

        location = "#{Console.pretty_path(test_case.path)}:#{test_case.line_range.last + 1}"
        puts indent_text("#{status_line} @ #{location}", 3)
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

      def show_failure_details(test_case, actual_results)
        return if actual_results.empty?

        puts indent_text('Expected vs Actual:', 4)
        actual_results.each_with_index do |result, idx|
          expected_line = test_case.expectations[idx] if test_case.expectations
          if expected_line
            puts indent_text("Expected: #{expected_line}", 5)
          end
          puts indent_text("Actual:   #{result.inspect}", 5)
        end
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
        return if result_status == :passed

        super
      end
    end
  end
end
