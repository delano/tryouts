# lib/tryouts/testbatch.rb

class Tryouts
  # Modern TestBatch that works with Prism-based data structures
  class TestBatch
    attr_reader :testrun, :failed, :container, :run_status

    def initialize(testrun)
      @testrun = testrun
      @container = Object.new  # Simple object instance for shared context
      @failed = 0
      @run_status = false
    end

    def empty?
      @testrun.empty?
    end

    def size
      @testrun.total_tests
    end

    def test_cases
      @testrun.test_cases
    end

    def path
      @testrun.source_file
    end

    # Execute the test batch
    def run(before_test = nil)
      return if empty?

      failed_count = 0

      # Run each test case in fresh context
      test_cases.each do |test_case|
        before_test&.call(test_case)

        begin
          test_result = execute_test_case_with_setup(test_case)
          failed_count += 1 if test_result == :failed
        rescue StandardError => ex
          failed_count += 1
          warn Console.color(:red, "Error in test: #{test_case.description}")
          warn Console.color(:red, ex.message)
          warn ex.backtrace.join($/), $/
        end

        yield(test_case) if block_given?  # For tallying/reporting
      end

      # Execute teardown code after all tests
      execute_teardown

      @failed = failed_count
      @run_status = true
      !failed?
    rescue StandardError => ex
      @failed = 1
      warn ex.message, ex.backtrace.join($/), $/
      false
    end

    def failed?
      @failed > 0
    end

    def run?
      @run_status
    end

    private

    # Execute test case with fresh setup context
    def execute_test_case_with_setup(test_case)
      return :skipped if test_case.empty? || !test_case.has_expectations?

      # Create fresh container for this test case
      fresh_container = Object.new

      # Execute setup code first in fresh context
      unless @testrun.setup.empty?
        setup_code = @testrun.setup.code
        setup_path = @testrun.setup.path
        setup_line = @testrun.setup.line_range.first

        Tryouts.debug "Executing setup for test: #{test_case.description}" if Tryouts.debug?
        fresh_container.instance_eval(setup_code, setup_path, setup_line)
      end

      # Execute test code in same fresh context
      test_code = test_case.code
      test_path = test_case.path
      test_line = test_case.line_range.first

      Tryouts.debug "Executing test case: #{test_case.description}" if Tryouts.debug?
      Tryouts.debug "Test code:\n#{test_code}" if Tryouts.debug?

      result = fresh_container.instance_eval(test_code, test_path, test_line)

      # Evaluate expectations in same fresh context
      expectations_passed = evaluate_expectations_in_context(test_case, result, fresh_container)

      expectations_passed ? :passed : :failed
    rescue StandardError => ex
      warn Console.color(:red, "Test execution failed: #{ex.message}")
      warn ex.backtrace.join($/), $/
      :failed
    end

    # Execute teardown code in the original container context
    def execute_teardown
      return if @testrun.teardown.empty?

      teardown_code = @testrun.teardown.code
      teardown_path = @testrun.teardown.path
      teardown_line = @testrun.teardown.line_range.first

      Tryouts.debug "Executing teardown code:\n#{teardown_code}" if Tryouts.debug?

      @container.instance_eval(teardown_code, teardown_path, teardown_line)
    rescue StandardError => ex
      warn Console.color(:red, "Teardown failed: #{ex.message}")
      warn ex.backtrace.join($/), $/
    end

    # Evaluate test case expectations against the result in given context
    def evaluate_expectations_in_context(test_case, result, context)
      return true if test_case.expectations.empty?

      test_case.expectations.all? do |expectation|
        expected_value = context.instance_eval(expectation, test_case.path, test_case.line_range.first)
        
        if result == expected_value
          Tryouts.debug "✓ Expected: #{expected_value.inspect}, Got: #{result.inspect}" if Tryouts.debug?
          true
        else
          Tryouts.debug "✗ Expected: #{expected_value.inspect}, Got: #{result.inspect}" if Tryouts.debug?
          false
        end
      rescue StandardError => ex
        warn Console.color(:red, "Expectation evaluation failed: #{ex.message}")
        false
      end
    end
  end
end
