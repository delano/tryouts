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
      def phase_header(message, file_count = nil, level = 0, io = $stderr)
        # Show processing header but skip execution phase headers to avoid empty lines
        case level
        when 0
          # Main processing header
          text = file_count ? "#{message}" : "#{message}..."
          io.puts text
        when 1
          # Skip execution phase headers - they create unwanted empty lines
          return
        else
          # Other phase headers with minimal formatting
          io.puts indent_text(message, level - 1)
        end
      end

      # File-level operations - compact single lines
      def file_start(file_path, _context_info = {}, io = $stderr)
        # See file_execution_start
      end

      def file_end(file_path, context_info = {}, io = $stderr)
        # No output in compact mode
      end

      def file_parsed(_file_path, test_count, io = $stderr, setup_present: false, teardown_present: false)
        # Don't show parsing info in compact mode unless debug
        return unless @show_debug

        extras = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        suffix = extras.empty? ? '' : " +#{extras.join(',')}"

        io.puts indent_text("Parsed #{test_count} tests#{suffix}", 1)
      end

      def file_execution_start(file_path, test_count, _context_mode, io = $stderr)
        pretty_path = Console.pretty_path(file_path)
        io.puts "#{pretty_path}: #{test_count} tests"
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time)
        # Skip - file_result already shows this information with better alignment
      end

      def file_result(_file_path, total_tests, failed_count, error_count, elapsed_time, io = $stdout)
        issues_count = failed_count + error_count
        passed_count = total_tests - issues_count
        details      = [
          # "#{passed_count} passed",
        ]

        if issues_count > 0
          status = Console.color(:red, '✗')
          details << "#{passed_count}/#{total_tests} passed"
        else
          status = Console.color(:green, '✓')
          details << "#{total_tests} passed"
        end

        if error_count > 0
          status = Console.color(:yellow, '⚠') if error_count == 0
          details << "#{error_count} errors"
        end

        if failed_count > 0
          status = Console.color(:yellow, '⚠') if failed_count == 0
          details << "#{failed_count} failed"
        end

        time_str = if elapsed_time
                     format_timing(elapsed_time)
                   else
                     ''
                   end
        io.puts "  #{status} #{details.join(', ')}#{time_str}"
      end

      # Test-level operations - only show in debug mode for compact
      def test_start(test_case, index, _total, io = $stdout)
        return unless @show_debug

        desc = test_case.description.to_s
        desc = "test #{index}" if desc.empty?

        io.puts "    Running: #{desc}"
      end

      def test_end(test_case, index, _total, io = $stdout)
        # No output for test end
      end

      def test_result(result_packet, io = $stdout)
        # Only show failed tests in compact mode unless show_passed is true
        return if result_packet.passed? && !@show_passed

        test_case = result_packet.test_case
        desc = test_case.description.to_s
        desc = 'unnamed test' if desc.empty?

        case result_packet.status
        when :passed
          status = Console.color(:green, '✓')
          io.puts indent_text("#{status} #{desc}", 1)
        when :failed
          status = Console.color(:red, '✗')
          io.puts indent_text("#{status} #{desc}", 1)

          # Show minimal context for failures
          if result_packet.actual_results.any?
            failure_info = "got: #{result_packet.first_actual.inspect}"
            io.puts indent_text("    #{failure_info}", 1)
          end

          # Show 1-2 lines of test context if available
          if test_case.source_lines && test_case.source_lines.size <= 3
            test_case.source_lines.each do |line|
              next if line.strip.empty? || line.strip.start_with?('#')
              io.puts indent_text("    #{line.strip}", 1)
              break # Only show first relevant line
            end
          end
        when :skipped
          status = Console.color(:yellow, '-')
          io.puts indent_text("#{status} #{desc}", 1)
        else
          status = '?'
          io.puts indent_text("#{status} #{desc}", 1)
        end
      end

      def test_output(_test_case, output_text, io = $stdout)
        # In compact mode, only show output for failed tests and only if debug mode is enabled
        return if output_text.nil? || output_text.strip.empty?
        return unless @show_debug

        io.puts "    Output: #{output_text.lines.count} lines"
        if output_text.lines.count <= 3
          output_text.lines.each do |line|
            io.puts "      #{line.chomp}"
          end
        else
          io.puts "      #{output_text.lines.first.chomp}"
          io.puts "      ... (#{output_text.lines.count - 2} more lines)"
          io.puts "      #{output_text.lines.last.chomp}"
        end
      end

      # Setup/teardown operations - minimal output
      def setup_start(_line_range)
        # No file setup start output for compact
      end

      def setup_output(output_text, io = $stderr)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        io.puts "    Setup output (#{lines} lines)"
      end

      def teardown_start(_line_range, io = $stderr)
        return unless @show_debug

        io.puts '    Teardown...'
      end

      def teardown_output(output_text, io = $stderr)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        io.puts "    Teardown output (#{lines} lines)"
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io = $stderr)
        io.puts
        io.puts '=' * 50

        issues_count = failed_count + error_count
        if issues_count > 0
          passed  = [total_tests - issues_count, 0].max  # Ensure passed never goes negative
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          result  = Console.color(:red, "#{details.join(', ')}, #{passed} passed")
        else
          result = Console.color(:green, "#{total_tests} tests passed")
        end

        time_str = format_timing(elapsed_time)

        io.puts "Total: #{result} (#{time_str})"
        io.puts "Files: #{successful_files} of #{total_files} successful"
      end

      # Debug and diagnostic output - minimal in compact mode
      def debug_info(message, level = 0, io = $stderr)
        return unless @show_debug

        io.puts indent_text("DEBUG: #{message}", level)
      end

      def trace_info(message, level = 0, io = $stderr)
        return unless @show_trace

        io.puts indent_text("TRACE: #{message}", level)
      end

      def error_message(message, backtrace = nil, io = $stderr)
        io.puts Console.color(:red, "ERROR: #{message}")

        return unless backtrace && @show_debug

        backtrace.first(3).each do |line|
          io.puts indent_text(line.chomp, 1)
        end
      end

      # Utility methods
      def raw_output(text, io = $stdout)
        io.puts text
      end

      def separator(style = :light, io = $stdout)
        case style
        when :heavy
          io.puts '=' * 50
        when :light
          io.puts '-' * 50
        when :dotted
          io.puts '.' * 50
        else
          io.puts '-' * 50
        end
      end

      private

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

    # Compact formatter that only shows failures and errors
    class CompactFailsFormatter < CompactFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def test_result(result_packet)
        # Only show failed/error tests
        return if result_packet.passed?

        super
      end
    end
  end
end
