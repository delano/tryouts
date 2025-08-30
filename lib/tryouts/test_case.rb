# lib/tryouts/testcase.rb

# Modern data structures using Ruby 3.2+ Data classes
class Tryouts
  # Core data structures
  TestCase = Data.define(:description, :code, :expectations, :line_range, :path, :source_lines, :first_expectation_line) do
    def empty?
      code.empty?
    end

    def expectations?
      !expectations.empty?
    end

    def exception_expectations?
      expectations.any?(&:exception?)
    end

    def regular_expectations
      expectations.filter(&:regular?)
    end

    def exception_expectations
      expectations.filter(&:exception?)
    end
  end

  Expectation = Data.define(:content, :type) do
    def regular? = type == :regular
    def exception? = type == :exception
    def boolean? = type == :boolean
    def true? = type == :true
    def false? = type == :false
    def result_type? = type == :result_type
    def regex_match? = type == :regex_match
    def performance_time? = type == :performance_time
    def intentional_failure? = type == :intentional_failure
    def output? = type == :output
  end

  # Special expectation type for output capturing with pipe information
  OutputExpectation = Data.define(:content, :type, :pipe) do
    def regular? = type == :regular
    def exception? = type == :exception
    def boolean? = type == :boolean
    def true? = type == :true
    def false? = type == :false
    def result_type? = type == :result_type
    def regex_match? = type == :regex_match
    def performance_time? = type == :performance_time
    def intentional_failure? = type == :intentional_failure
    def output? = type == :output

    def stdout? = pipe == 1
    def stderr? = pipe == 2
  end

  Setup = Data.define(:code, :line_range, :path) do
    def empty?
      code.empty?
    end
  end

  Teardown = Data.define(:code, :line_range, :path) do
    def empty?
      code.empty?
    end
  end

  Testrun = Data.define(:setup, :test_cases, :teardown, :source_file, :metadata, :warnings) do
    def total_tests
      test_cases.size
    end

    def empty?
      test_cases.empty?
    end
  end

  # Test case result packet for formatters
  # Replaces the simple Hash aggregation with a rich, immutable data structure
  # containing all execution context and results needed by formatters
  TestCaseResultPacket = Data.define(
    :test_case,          # TestCase object
    :status,             # :passed, :failed, :error
    :result_value,       # Actual execution result
    :actual_results,     # Array of actual values from expectations
    :expected_results,   # Array of expected values from expectations
    :error,              # Exception object (if any)
    :captured_output,    # Captured stdout/stderr content
    :elapsed_time,       # Execution timing (future use)
    :metadata,            # Hash for future extensibility
  ) do
    def passed?
      status == :passed
    end

    def failed?
      status == :failed
    end

    def error?
      status == :error
    end

    def has_output?
      captured_output && !captured_output.empty?
    end

    def has_error?
      !error.nil?
    end

    # Helper for formatter access to first actual/expected values
    def first_actual
      actual_results&.first
    end

    def first_expected
      expected_results&.first
    end

    # Create a basic result packet for successful tests
    def self.from_success(test_case, result_value, actual_results, expected_results, captured_output: nil, elapsed_time: nil, metadata: {})
      new(
        test_case: test_case,
        status: :passed,
        result_value: result_value,
        actual_results: actual_results,
        expected_results: expected_results,
        error: nil,
        captured_output: captured_output,
        elapsed_time: elapsed_time,
        metadata: metadata,
      )
    end

    # Create a result packet for failed tests
    def self.from_failure(test_case, result_value, actual_results, expected_results, captured_output: nil, elapsed_time: nil, metadata: {})
      new(
        test_case: test_case,
        status: :failed,
        result_value: result_value,
        actual_results: actual_results,
        expected_results: expected_results,
        error: nil,
        captured_output: captured_output,
        elapsed_time: elapsed_time,
        metadata: metadata,
      )
    end

    # Create a result packet for error cases
    def self.from_error(test_case, error, captured_output: nil, elapsed_time: nil, metadata: {})
      error_message = error ? error.message : '<exception is nil>'

      # Include backtrace in error message when stack traces are enabled
      error_display = if error && Tryouts.stack_traces?
        backtrace_preview = Console.pretty_backtrace(error.backtrace, limit: 3).join("\n    ")
        "(#{error.class}) #{error_message}\n    #{backtrace_preview}"
      else
        "(#{error.class}) #{error_message}"
      end

      new(
        test_case: test_case,
        status: :error,
        result_value: nil,
        actual_results: [error_display],
        expected_results: [],
        error: error,
        captured_output: captured_output,
        elapsed_time: elapsed_time,
        metadata: metadata,
      )
    end
  end

  # Enhanced error with context
  class TryoutSyntaxError < StandardError
    attr_reader :line_number, :context, :source_file

    def initialize(message, line_number:, context:, source_file: nil)
      @line_number = line_number
      @context     = context
      @source_file = source_file

      location = source_file ? "#{source_file}:#{line_number}" : "line #{line_number}"
      super("#{message} at #{location}: #{context}")
    end
  end
end
