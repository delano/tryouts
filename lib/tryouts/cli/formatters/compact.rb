# lib/tryouts/cli/formatters/compact.rb

class Tryouts
  class CLI
    # Compact single-line formatter
    class CompactFormatter
      include FormatterInterface

      def initialize(options = {})
        @show_file_header = options.fetch(:show_file_header, true)
      end

      def format_file_header(testrun)
        return '' unless @show_file_header

        case testrun
        in { source_file: String => path }
          "Running: #{File.basename(path)}"
        else
          ''
        end
      end

      def format_test_result(test_case, result_status, actual_results = [])
        case [test_case, result_status]
        in [{ description: String => desc }, :passed]
          Console.color(:green, "✓ #{desc}")
        in [{ description: String => desc }, :failed]
          failure_details = actual_results.empty? ? '' : " (got: #{actual_results.first.inspect})"
          Console.color(:red, "✗ #{desc}#{failure_details}")
        in [{ description: String => desc }, :skipped]
          Console.color(:yellow, "- #{desc}")
        else
          "? #{begin
                test_case.description
          rescue StandardError
                'Unknown test'
          end}"
        end
      end

      def format_summary(total_tests, failed_count, elapsed_time = nil)
        case [total_tests, failed_count]
        in [Integer => total, 0]
          time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
          Console.color(:green, "#{total} tests passed#{time_str}")
        in [Integer => total, Integer => failed] if failed > 0
          passed   = total - failed
          time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
          Console.color(:red, "#{failed} failed, #{passed} passed#{time_str}")
        else
          'Tests completed'
        end
      end
    end
  end
end
