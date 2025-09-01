# lib/tryouts/test_result_aggregator.rb

require_relative 'failure_collector'
require 'concurrent'

class Tryouts
  # Centralized test result aggregation to ensure counting consistency
  # across all formatters and eliminate counting discrepancies
  class TestResultAggregator
    def initialize
      @failure_collector       = FailureCollector.new
      # Use thread-safe atomic counters
      @test_counts             = {
        total_tests: Concurrent::AtomicFixnum.new(0),
        passed: Concurrent::AtomicFixnum.new(0),
        failed: Concurrent::AtomicFixnum.new(0),
        errors: Concurrent::AtomicFixnum.new(0),
      }
      @infrastructure_failures = Concurrent::Array.new
      @file_counts             = {
        total: Concurrent::AtomicFixnum.new(0),
        successful: Concurrent::AtomicFixnum.new(0),
      }
    end

    attr_reader :failure_collector

    # Add a test-level result (from individual test execution)
    def add_test_result(file_path, result_packet)
      @test_counts[:total_tests].increment

      if result_packet.passed?
        @test_counts[:passed].increment
      elsif result_packet.failed?
        @test_counts[:failed].increment
        @failure_collector.add_failure(file_path, result_packet)
      elsif result_packet.error?
        @test_counts[:errors].increment
        @failure_collector.add_failure(file_path, result_packet)
      end
    end

    # Add an infrastructure-level failure (setup, teardown, file-level)
    def add_infrastructure_failure(type, file_path, error_message, exception = nil)
      @infrastructure_failures << {
        type: type,           # :setup, :teardown, :file_processing
        file_path: file_path,
        error_message: error_message,
        exception: exception,
      }
    end

    # Atomic increment methods for file-level operations
    def increment_total_files
      @file_counts[:total].increment
    end

    def increment_successful_files
      @file_counts[:successful].increment
    end

    # Get count of infrastructure failures
    def infrastructure_failure_count
      @infrastructure_failures.size
    end

    # Get counts that should be displayed in numbered failure lists
    # These match what actually appears in the failure summary
    def get_display_counts
      {
        total_tests: @test_counts[:total_tests].value,
        passed: @test_counts[:passed].value,
        failed: @failure_collector.failure_count,
        errors: @failure_collector.error_count,
        total_issues: @failure_collector.total_issues,
      }
    end

    # Get total counts including infrastructure failures
    # These represent all issues that occurred during test execution
    def get_total_counts
      display = get_display_counts
      {
        total_tests: display[:total_tests],
        passed: display[:passed],
        failed: display[:failed],
        errors: display[:errors],
        infrastructure_failures: @infrastructure_failures.size,
        total_issues: display[:total_issues] + @infrastructure_failures.size,
      }
    end

    # Get file-level statistics
    def get_file_counts
      {
        total: @file_counts[:total].value,
        successful: @file_counts[:successful].value,
      }
    end

    # Get infrastructure failures for detailed reporting
    def get_infrastructure_failures
      @infrastructure_failures.dup
    end

    # Check if there are any failures at all
    def any_failures?
      @failure_collector.any_failures? || !@infrastructure_failures.empty?
    end

    # Check if there are displayable failures (for numbered lists)
    def any_display_failures?
      @failure_collector.any_failures?
    end

    # Reset for testing purposes
    def clear
      @failure_collector.clear
      @test_counts[:total_tests].update { |_| 0 }
      @test_counts[:passed].update { |_| 0 }
      @test_counts[:failed].update { |_| 0 }
      @test_counts[:errors].update { |_| 0 }
      @infrastructure_failures.clear
      @file_counts[:total].update { |_| 0 }
      @file_counts[:successful].update { |_| 0 }
    end

    # Provide a summary string for debugging
    def summary
      display = get_display_counts
      total   = get_total_counts

      parts = []
      parts << "#{display[:passed]} passed" if display[:passed] > 0
      parts << "#{display[:failed]} failed" if display[:failed] > 0
      parts << "#{display[:errors]} errors" if display[:errors] > 0
      parts << "#{total[:infrastructure_failures]} infrastructure failures" if total[:infrastructure_failures] > 0

      parts.empty? ? 'All tests passed' : parts.join(', ')
    end
  end
end
