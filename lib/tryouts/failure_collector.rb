# lib/tryouts/failure_collector.rb
#
# frozen_string_literal: true

require_relative 'console'
require_relative 'expectation_evaluators/evaluation_context'

class Tryouts
  # Collects and organizes failed test results across files for summary display
  # Similar to RSpec's failure summary at the end of test runs
  class FailureCollector
    # The failure reason is rendered when the entry is made, right after the
    # test ran: a value's inspect may depend on constants or state that a
    # later test or the end of the file changes.
    FailureEntry = Data.define(:file_path, :test_case, :result_packet, :failure_reason) do
      def initialize(file_path:, test_case:, result_packet:, failure_reason: nil)
        failure_reason ||= FailureEntry.reason_for(result_packet, file_path)
        super
      end

      def self.reason_for(result_packet, file_path)
        case result_packet.status
        when :failed
          if !result_packet.actual_results.empty? && !result_packet.expected_results.empty?
            expected = result_packet.failed_expected
            FailureCollector.expectation_error(expected, file_path) ||
              "expected #{FailureCollector.inspect_value(expected)}, got #{FailureCollector.inspect_value(result_packet.failed_actual)}"
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

      def line_number
        result_packet.failure_line
      end

      def description
        desc = test_case.description.to_s.strip
        desc.empty? ? 'unnamed test' : desc
      end

      def source_context
        return [] unless test_case.source_lines

        # Show the test code (excluding setup/teardown)
        test_case.source_lines.reject do |line|
          line.strip.empty? || line.strip.start_with?('#')
        end.first(3) # Limit to first 3 relevant lines
      end
    end

    # Kernel#class, for a value that has no class method of its own (a
    # BasicObject) or one that gives something else
    CLASS_OF = Kernel.instance_method(:class)

    # A value's inspect is user code and can raise; no report of the value
    # may. Every formatter shows a test's values through this.
    def self.inspect_value(value)
      value.inspect
    rescue StandardError => ex
      "#<#{CLASS_OF.bind_call(value)} (inspect raised #{ex.class}: #{ex.message})>"
    end

    # An expectation that raised while it was evaluated (a syntax error, an
    # undefined name) has an EvaluationError for its expected value; see
    # ExpectationEvaluators::Base#handle_evaluation_error. Returns its
    # message without the "path:line: " the test file's location already
    # gives, or nil for an ordinary expected value.
    def self.expectation_error(expected, path)
      return unless expected.is_a?(ExpectationEvaluators::EvaluationError)

      expected.message.sub(/\A#{Regexp.escape(path.to_s)}:\d+: /, '')
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
