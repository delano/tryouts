# lib/tryouts/cli/formatters/base.rb

class Tryouts
  class CLI
    # Common interface for all test result formatters using Ruby 3.4+ patterns
    module FormatterInterface
      def format_file_header(testrun)
        raise NotImplementedError, "#{self.class} must implement #format_file_header"
      end

      def format_test_result(test_case, result_status, actual_results = [])
        raise NotImplementedError, "#{self.class} must implement #format_test_result"
      end

      def format_summary(total_tests, failed_count, elapsed_time = nil)
        raise NotImplementedError, "#{self.class} must implement #format_summary"
      end
    end

    # Factory for creating formatters based on options using pattern matching
    class FormatterFactory
      def self.create(options = {})
        case options
        in { verbose: true, fails_only: true }
          VerboseFailsFormatter.new(options)
        in { verbose: true }
          VerboseFormatter.new(options)
        in { quiet: true }
          QuietFormatter.new(options)
        in { compact: true } | {} | _
          CompactFormatter.new(options)
        end
      end
    end
  end
end
