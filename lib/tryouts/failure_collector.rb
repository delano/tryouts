# lib/tryouts/failure_collector.rb

require_relative 'console'

class Tryouts
  # Collects and organizes failed test results across files for summary display
  # Similar to RSpec's failure summary at the end of test runs
  class FailureCollector
    # Data structure for a single failure entry
    FailureEntry = Data.define(:file_path, :test_case, :result_packet) do
      def line_number
        # Use first expectation line for consistency with main error display
        test_case.first_expectation_line || test_case.line_range&.first || 0
      end

      def description
        desc = test_case.description.to_s.strip
        desc.empty? ? 'unnamed test' : desc
      end

      def failure_reason
        case result_packet.status
        when :failed
          if result_packet.actual_results.any? && result_packet.expected_results.any?
            "expected #{result_packet.first_expected.inspect}, got #{result_packet.first_actual.inspect}"
          else
            'test failed'
          end
        when :error
          error_msg = result_packet.error&.message || 'unknown error'
          "#{result_packet.error&.class&.name || 'Error'}: #{error_msg}"
        else
          'test did not pass'
        end
      end

      def source_context
        return [] unless test_case.source_lines

        # Show the test code (excluding setup/teardown)
        test_case.source_lines.reject do |line|
          line.strip.empty? || line.strip.start_with?('#')
        end.first(3) # Limit to first 3 relevant lines
      end
    end

    def initialize
      @failures            = []
      @files_with_failures = Set.new
    end

    # Add a failed test result
    def add_failure(file_path, result_packet)
      return unless result_packet.failed? || result_packet.error?

      entry = FailureEntry.new(
        file_path: file_path,
        test_case: result_packet.test_case,
        result_packet: result_packet,
      )

      @failures << entry
      @files_with_failures << file_path
    end

    # Check if any failures were collected
    def any_failures?
      !@failures.empty?
    end

    # Get count of total failures
    def failure_count
      @failures.count { |f| f.result_packet.failed? }
    end

    # Get count of total errors
    def error_count
      @failures.count { |f| f.result_packet.error? }
    end

    # Get total issues (failures + errors)
    def total_issues
      @failures.size
    end

    # Get count of files with failures
    def files_with_failures_count
      @files_with_failures.size
    end

    # Get failures grouped by file for summary display
    def failures_by_file
      @failures.group_by(&:file_path).transform_values do |file_failures|
        file_failures.sort_by(&:line_number)
      end
    end

    # Get all failure entries (for detailed processing)
    def all_failures
      @failures.dup
    end

    # Reset the collector (useful for testing)
    def clear
      @failures.clear
      @files_with_failures.clear
    end
  end
end
