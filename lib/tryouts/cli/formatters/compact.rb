# lib/tryouts/cli/formatters/compact.rb

class Tryouts
  class CLI
    # Compact single-line formatter focused on results
    class CompactFormatter
      include FormatterInterface

      def initialize(options = {})
        @show_debug        = options.fetch(:debug, false)
        @show_trace        = options.fetch(:trace, false)
        @show_passed       = options.fetch(:show_passed, true)
      end

      # Phase-level output - minimal for compact mode
      def phase_header(message, _file_count = nil, level = 0)
        # Skip execution phase headers in compact mode - they create unwanted empty lines
        return if level >= 1

        text       = "#{message}..."
        puts indent_text(text, level)
      end

      # File-level operations - compact single lines
      def file_start(file_path, context_info = {})
        return unless @show_debug

        framework   = context_info[:framework] || :direct
        context     = context_info[:context] || :fresh
        pretty_path = Console.pretty_path(file_path)

        puts indent_text("Running: #{pretty_path} (#{framework}/#{context})", 1)
      end

      def file_parsed(_file_path, test_count, setup_present: false, teardown_present: false)
        # Don't show parsing info in compact mode unless debug
        return unless @show_debug

        extras = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        suffix = extras.empty? ? '' : " +#{extras.join(',')}"

        puts indent_text("Parsed #{test_count} tests#{suffix}", 1)
      end

      def file_execution_start(file_path, test_count, _context_mode)
        pretty_path = Console.pretty_path(file_path)
        puts
        puts "#{pretty_path}: #{test_count} tests"
      end

      def file_result(_file_path, total_tests, failed_count, error_count, elapsed_time)
        detail = []
        if failed_count > 0
          status = Console.color(:red, '✗')
          detail << "#{failed_count}/#{total_tests} failed"
        else
          status = Console.color(:green, '✓')
          detail << "#{total_tests} passed"
        end

        if error_count > 0
          status = Console.color(:yellow, '⚠') if failed_count == 0
          detail << "#{error_count} errors"
        end

        time_str = if elapsed_time
                     if elapsed_time < 2
                       " (#{(elapsed_time * 1000).to_i}ms)"
                     else
                       " (#{elapsed_time.round(2)}s)"
                     end
                   else
                     ''
                   end
        puts "  #{status} #{detail.join(', ')}#{time_str}"
      end

      # Test-level operations - only show in debug mode for compact
      def test_start(test_case, index, _total)
        return unless @show_debug

        desc = test_case.description.to_s
        desc = "test #{index}" if desc.empty?
        puts "    Running: #{desc}"
      end

      def test_result(test_case, result_status, actual_results = [], _elapsed_time = nil)
        # Only show failed tests in compact mode unless show_passed is true
        return if result_status == :passed && !@show_passed

        desc = test_case.description.to_s
        desc = 'unnamed test' if desc.empty?

        case result_status
        when :passed
          status = Console.color(:green, '✓')
        when :failed
          status = Console.color(:red, '✗')
          if actual_results.any?
            failure_info = " (got: #{actual_results.first.inspect})"
            desc        += failure_info
          end
        when :skipped
          status = Console.color(:yellow, '-')
        else
          status = '?'
        end

        puts indent_text("#{status} #{desc}", 1)
      end

      def test_output(test_case, output_text)
        # In compact mode, only show output for failed tests and only if debug mode is enabled
        return if output_text.nil? || output_text.strip.empty?
        return unless @show_debug

        puts "    Output: #{output_text.lines.count} lines"
        if output_text.lines.count <= 3
          output_text.lines.each do |line|
            puts "      #{line.chomp}"
          end
        else
          puts "      #{output_text.lines.first.chomp}"
          puts "      ... (#{output_text.lines.count - 2} more lines)"
          puts "      #{output_text.lines.last.chomp}"
        end
      end

      # Setup/teardown operations - minimal output
      def setup_start(_line_range)
        # No file setup start output for compact
      end

      def setup_output(output_text)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        puts "    Setup output (#{lines} lines)"
      end

      def teardown_start(_line_range)
        return unless @show_debug

        puts '    Teardown...'
      end

      def teardown_output(output_text)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        puts "    Teardown output (#{lines} lines)"
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time)
        # Skip - file_result already shows this information with better alignment
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
        puts
        puts '=' * 50

        issues_count = failed_count + error_count
        if issues_count > 0
          passed  = total_tests - issues_count
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          result  = Console.color(:red, "#{details.join(', ')}, #{passed} passed")
        else
          result = Console.color(:green, "#{total_tests} tests passed")
        end

        time_str = if elapsed_time < 2
                     "#{(elapsed_time * 1000).to_i}ms"
                   else
                     "#{elapsed_time.round(2)}s"
                   end

        puts "Total: #{result} (#{time_str})"
        puts "Files: #{successful_files} of #{total_files} successful"
      end

      # Debug and diagnostic output - minimal in compact mode
      def debug_info(message, level = 0)
        return unless @show_debug

        puts indent_text("DEBUG: #{message}", level)
      end

      def trace_info(message, level = 0)
        return unless @show_trace

        puts indent_text("TRACE: #{message}", level)
      end

      def error_message(message, backtrace = nil)
        puts Console.color(:red, "ERROR: #{message}")

        return unless backtrace && @show_debug

        backtrace.first(3).each do |line|
          puts indent_text(line.chomp, 1)
        end
      end

      # Utility methods
      def raw_output(text)
        puts text
      end

      def separator(style = :light)
        case style
        when :heavy
          puts '=' * 50
        when :light
          puts '-' * 50
        when :dotted
          puts '.' * 50
        else
          puts '-' * 50
        end
      end
    end

    # Compact formatter that only shows failures and errors
    class CompactFailsFormatter < CompactFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil)
        # Only show failed/error tests
        return if result_status == :passed

        super
      end
    end
  end
end
