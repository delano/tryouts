# lib/tryouts/cli/formatters/quiet.rb

class Tryouts
  class CLI
    # Minimal output formatter
    class QuietFormatter
      include FormatterInterface

      def format_file_header(_testrun)
        '' # No file header in quiet mode
      end

      def format_test_result(_test_case, result_status, _actual_results = [])
        case result_status
        in :passed
          Console.color(:green, '.')
        in :failed
          Console.color(:red, 'F')
        in :skipped
          Console.color(:yellow, 'S')
        else
          '?'
        end
      end

      def format_summary(total_tests, failed_count, _elapsed_time = nil)
        case [total_tests, failed_count]
        in [Integer => total, 0]
          Console.color(:green, "\n#{total} passed")
        in [Integer => total, Integer => failed] if failed > 0
          Console.color(:red, "\n#{failed} failed, #{total - failed} passed")
        else
          "\nCompleted"
        end
      end
    end
  end
end
