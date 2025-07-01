# lib/tryouts/data_structures.rb

# Modern data structures using Ruby 3.2+ Data classes
class Tryouts
  # Core data structures
  PrismTestCase = Data.define(:description, :code, :expectations, :line_range, :path) do
    def empty?
      code.empty?
    end

    def has_expectations?
      !expectations.empty?
    end
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
