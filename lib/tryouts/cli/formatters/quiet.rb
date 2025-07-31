# lib/tryouts/cli/formatters/quiet.rb

class Tryouts
  class CLI
    # Minimal output formatter - only shows essential information
    class QuietFormatter
      include FormatterInterface

      def initialize(options = {})
        @show_errors        = options.fetch(:show_errors, true)
        @show_final_summary = options.fetch(:show_final_summary, true)
        @current_file       = nil
      end

      # Phase-level output - silent
      def phase_header(message, file_count = nil, level = nil, io = $stdout)
        # Silent in quiet mode
      end

      # File-level operations - minimal
      def file_start(file_path, context_info = {}, io = $stdout)
        # Silent in quiet mode
      end

      def file_end(_file_path, _context_info = {}, io = $stderr)
        io.puts # add newline after all dots
      end

      def file_parsed(file_path, test_count, io = $stdout, setup_present: false, teardown_present: false)
        # Silent in quiet mode
      end

      def file_execution_start(file_path, _test_count, _context_mode, io = $stdout)
        @current_file = file_path
      end

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time, io = $stdout)
        # Silent in quiet mode - results shown in batch_summary
      end

      # Test-level operations - dot notation
      def test_start(test_case, index, total, io = $stdout)
        # Silent in quiet mode
      end

      def test_end(test_case, index, total, io = $stderr)
        # Silent in quiet mode
      end

      def test_result(result_packet, io = $stderr)
        case result_packet.status
        when :passed
          io.print Console.color(:green, '.')
        when :failed
          io.print Console.color(:red, 'F')
        when :error
          io.print Console.color(:red, 'E')
        when :skipped
          io.print Console.color(:yellow, 'S')
        else
          io.print '?'
        end
        io.flush
      end

      def test_output(test_case, output_text)
        # Silent in quiet mode - could optionally show output for failed tests only
        # For now, keeping it completely silent
      end

      # Setup/teardown operations - silent
      def setup_start(line_range, io = $stdout)
        # Silent in quiet mode
      end

      def setup_output(output_text, io = $stdout)
        # Silent in quiet mode
      end

      def teardown_start(line_range, io = $stdout)
        # Silent in quiet mode
      end

      def teardown_output(output_text, io = $stdout)
        # Silent in quiet mode
      end

      # Summary operations - quiet mode skips failure summary
      def batch_summary(failure_collector, io = $stderr)
        # Quiet formatter defaults to no failure summary
        # Users can override with --failure-summary if needed
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io = $stderr)
        return unless @show_final_summary

        puts

        time_str = if elapsed_time < 2
                     "#{(elapsed_time * 1000).to_i}ms"
                   else
                     "#{elapsed_time.round(2)}s"
                   end

        issues_count = failed_count + error_count
        if issues_count > 0
          passed  = [total_tests - issues_count, 0].max  # Ensure passed never goes negative
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          io.puts Console.color(:red, "Total: #{details.join(', ')}, #{passed} passed (#{time_str})")
        else
          io.puts Console.color(:green, "Total: #{total_tests} passed (#{time_str})")
        end

        if total_files > 1
          io.puts "Files: #{successful_files} of #{total_files} successful"
        end
      end

      # Debug and diagnostic output - silent unless errors
      def debug_info(message, level = 0, io = $stderr)
        # Silent in quiet mode
      end

      def trace_info(message, level = 0, io = $stderr)
        # Silent in quiet mode
      end

      def error_message(message, backtrace = nil, io = $stderr)
        return unless @show_errors

        io.puts
        io.puts Console.color(:red, "ERROR: #{message}")

        return unless backtrace && @show_debug

        backtrace.first(3).each do |line|
          io.puts "  #{line.chomp}"
        end
      end

      # Utility methods
      def raw_output(text, io = $stderr)
        io.puts text if @show_final_summary
      end

      def separator(style = :light)
        # Silent in quiet mode
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # Quiet can work with coordinated output
          output_frequency: :low,          # Very minimal output, mainly dots
          requires_tty: false              # Works without TTY
        }
      end
    end

    # Quiet formatter that only shows dots for failures and errors
    class QuietFailsFormatter < QuietFormatter
      def test_result(result_packet, io = $stderr)
        # Only show non-pass dots in fails mode
        return if result_packet.passed?

        super
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # QuietFails can work with coordinated output
          output_frequency: :low,          # Very minimal output
          requires_tty: false              # Works without TTY
        }
      end
    end
  end
end
