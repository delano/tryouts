# lib/tryouts/cli/formatters/quiet.rb

class Tryouts
  class CLI
    # Minimal output formatter - only shows essential information
    class QuietFormatter
      include FormatterInterface

      def initialize(options = {})
        super
        @show_errors        = options.fetch(:show_errors, true)
        @show_final_summary = options.fetch(:show_final_summary, true)
        @current_file       = nil
      end

      def file_execution_start(file_path, test_count:, context_mode:)
        @current_file = file_path
      end

      def file_end(_file_path, context_info: {})
        # Always use coordinated output through puts() method
        # puts # add newline after all dots
      end

      def test_result(result_packet)
        char = case result_packet.status
               when :passed
                 Console.color(:green, '.')
               when :failed
                 Console.color(:red, 'F')
               when :error
                 Console.color(:red, 'E')
               when :skipped
                 Console.color(:yellow, 'S')
               else
                 '?'
               end

        # Always use coordinated output through write() method
        write(char)
      end

      # Summary operations - quiet mode skips failure summary
      def batch_summary(failure_collector)
        # Quiet formatter defaults to no failure summary
        # Users can override with --failure-summary if needed
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:)
        return unless @show_final_summary

        puts
        puts # Add newline after dots

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
          puts Console.color(:red, "Total: #{details.join(', ')}, #{passed} passed (#{time_str})")
        else
          puts Console.color(:green, "Total: #{total_tests} passed (#{time_str})")
        end

        if total_files > 1
          puts "Files: #{successful_files} of #{total_files} successful"
        end
      end

      def error_message(message, backtrace: nil)
        return unless @show_errors

        @stderr.puts
        @stderr.puts Console.color(:red, "ERROR: #{message}")

        return unless backtrace && @show_debug

        backtrace.first(3).each do |line|
          @stderr.puts "  #{line.chomp}"
        end
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # Quiet can work with coordinated output
          output_frequency: :low,          # Very minimal output, mainly dots
          requires_tty: false,             # Works without TTY
        }
      end
    end

    # Quiet formatter that only shows dots for failures and errors
    class QuietFailsFormatter < QuietFormatter
      def test_result(result_packet)
        # Only show non-pass dots in fails mode
        return if result_packet.passed?

        super
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # QuietFails can work with coordinated output
          output_frequency: :low,          # Very minimal output
          requires_tty: false,             # Works without TTY
        }
      end
    end
  end
end
