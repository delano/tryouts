# lib/tryouts/testcase.rb

# Modern data structures using Ruby 3.2+ Data classes
class Tryouts
  # Core data structures
  TestCase = Data.define(:description, :code, :expectations, :line_range, :path, :source_lines) do
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

  Testrun = Data.define(:setup, :test_cases, :teardown, :source_file, :metadata) do
    def total_tests
      test_cases.size
    end

    def empty?
      test_cases.empty?
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
