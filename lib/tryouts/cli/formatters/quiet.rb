# lib/tryouts/cli/formatters/quiet.rb

class Tryouts
  class CLI
    # Minimal output formatter - only shows essential information
    class QuietFormatter
      include FormatterInterface

      def initialize(options = {})
        @show_errors        = options.fetch(:show_errors, true)
        @show_final_summary = options.fetch(:show_final_summary, true)
      end

      # Phase-level output - silent
      def phase_header(message, file_count = nil)
        # Silent in quiet mode
      end

      # File-level operations - minimal
      def file_start(file_path, context_info = {})
        # Silent in quiet mode
      end

      def file_parsed(file_path, test_count, setup_present: false, teardown_present: false)
        # Silent in quiet mode
      end

      def file_execution_start(file_path, test_count, context_mode)
        # Silent in quiet mode
      end

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time)
        # Silent in quiet mode - results shown in batch_summary
      end

      # Test-level operations - dot notation
      def test_start(test_case, index, total)
        # Silent in quiet mode
      end

      def test_result(_test_case, result_status, _actual_results = [], _elapsed_time = nil)
        case result_status
        when :passed
          print Console.color(:green, '.')
        when :failed
          print Console.color(:red, 'F')
        when :skipped
          print Console.color(:yellow, 'S')
        else
          print '?'
        end
        $stdout.flush
      end

      # Setup/teardown operations - silent
      def setup_start(line_range)
        # Silent in quiet mode
      end

      def setup_output(output_text)
        # Silent in quiet mode
      end

      def teardown_start(line_range)
        # Silent in quiet mode
      end

      def teardown_output(output_text)
        # Silent in quiet mode
      end

      # Summary operations - show results
      def batch_summary(total_tests, failed_count, elapsed_time)
        return unless @show_final_summary

        puts # New line after dots

        if failed_count > 0
          passed   = total_tests - failed_count
          time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
          puts Console.color(:red, "#{failed_count} failed, #{passed} passed#{time_str}")
        else
          time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
          puts Console.color(:green, "#{total_tests} passed#{time_str}")
        end
      end

      def grand_total(total_tests, failed_count, successful_files, total_files, elapsed_time)
        return unless @show_final_summary

        puts

        if failed_count > 0
          passed = total_tests - failed_count
          puts Console.color(:red, "Total: #{failed_count} failed, #{passed} passed (#{elapsed_time.round(2)}s)")
        else
          puts Console.color(:green, "Total: #{total_tests} passed (#{elapsed_time.round(2)}s)")
        end

        if total_files > 1
          puts "Files: #{successful_files}/#{total_files} successful"
        end
      end

      # Debug and diagnostic output - silent unless errors
      def debug_info(message, level = 0)
        # Silent in quiet mode
      end

      def trace_info(message, level = 0)
        # Silent in quiet mode
      end

      def error_message(message, _details = nil)
        return unless @show_errors

        puts
        puts Console.color(:red, "ERROR: #{message}")
      end

      # Utility methods
      def raw_output(text)
        puts text if @show_final_summary
      end

      def separator(style = :light)
        # Silent in quiet mode
      end
    end
  end
end
