# lib/tryouts/testbatch.rb

require_relative 'verbose_formatter'

class Tryouts
  # Modern TestBatch that works with Prism-based data structures
  class TestBatch
    attr_reader :testrun, :failed, :container, :run_status, :test_results

    def initialize(testrun, shared_context: false, verbose: false, fails_only: false)
      @testrun        = testrun
      @container      = Object.new  # Simple object instance for shared context
      @shared_context = shared_context
      @verbose        = verbose
      @fails_only     = fails_only
      @failed         = 0
      @run_status     = false
      @test_results   = []  # Store detailed results for verbose output
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

      # Show file header in verbose mode
      if @verbose
        formatter = create_verbose_formatter
        puts formatter.format_file_header
      end

      if @shared_context
        # Shared context mode: setup once, all tests share state
        execute_setup_once

        test_cases.each do |test_case|
          before_test&.call(test_case)

          begin
            test_result, actual_results = execute_test_case_shared(test_case)

            result_data = {
              test_case: test_case,
              status: test_result,
              actual_results: actual_results,
            }
            @test_results << result_data

            failed_count += 1 if test_result == :failed

            # Show verbose output if enabled
            show_verbose_output(result_data) if show_verbose_output?(test_result)
          rescue StandardError => ex
            failed_count += 1
            handle_test_error(test_case, ex)
          end

          yield(test_case) if block_given?
        end

        execute_teardown
      else
        # Fresh context mode: setup before each test
        test_cases.each do |test_case|
          before_test&.call(test_case)

          begin
            test_result, actual_results = execute_test_case_with_setup(test_case)

            result_data = {
              test_case: test_case,
              status: test_result,
              actual_results: actual_results,
            }
            @test_results << result_data

            failed_count += 1 if test_result == :failed

            # Show verbose output if enabled
            show_verbose_output(result_data) if show_verbose_output?(test_result)
          rescue StandardError => ex
            failed_count += 1
            handle_test_error(test_case, ex)
          end

          yield(test_case) if block_given?
        end

        execute_teardown
      end

      @failed     = failed_count
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

    # Execute setup once at the beginning (shared context mode)
    def execute_setup_once
      return if @testrun.setup.empty?

      setup_code = @testrun.setup.code
      setup_path = @testrun.setup.path
      setup_line = @testrun.setup.line_range.first

      Tryouts.debug "Executing setup once (shared context):\n#{setup_code}" if Tryouts.debug?
      @container.instance_eval(setup_code, setup_path, setup_line)
    rescue StandardError => ex
      warn Console.color(:red, "Setup failed: #{ex.message}")
      warn ex.backtrace.join($/), $/
      raise
    end

    # Execute test case in shared context (no setup per test)
    def execute_test_case_shared(test_case)
      return [:skipped, []] if test_case.empty? || !test_case.expectations?

      test_code = test_case.code
      test_path = test_case.path
      test_line = test_case.line_range.first

      Tryouts.debug "Executing test case (shared): #{test_case.description}" if Tryouts.debug?
      Tryouts.debug "Test code:\n#{test_code}" if Tryouts.debug?

      # Execute test in shared container context
      result = @container.instance_eval(test_code, test_path, test_line)

      # Evaluate expectations in same shared context and collect actual results
      expectations_passed, actual_results = evaluate_expectations_in_context(test_case, result, @container)

      [expectations_passed ? :passed : :failed, actual_results]
    rescue StandardError => ex
      warn Console.color(:red, "Test execution failed: #{ex.message}")
      warn ex.backtrace.join($/), $/
      [:failed, []]
    end

    # Execute test case with fresh setup context
    def execute_test_case_with_setup(test_case)
      return [:skipped, []] if test_case.empty? || !test_case.expectations?

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

      # Evaluate expectations in same fresh context and collect actual results
      expectations_passed, actual_results = evaluate_expectations_in_context(test_case, result, fresh_container)

      [expectations_passed ? :passed : :failed, actual_results]
    rescue StandardError => ex
      warn Console.color(:red, "Test execution failed: #{ex.message}")
      warn ex.backtrace.join($/), $/
      [:failed, []]
    end

    # Execute teardown code in the container context
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
      return [true, []] if test_case.expectations.empty?

      actual_results = []
      all_passed     = true

      test_case.expectations.each do |expectation|
        expected_value = context.instance_eval(expectation, test_case.path, test_case.line_range.first)
        actual_results << result

        if result == expected_value
          Tryouts.debug "✓ Expected: #{expected_value.inspect}, Got: #{result.inspect}" if Tryouts.debug?
        else
          Tryouts.debug "✗ Expected: #{expected_value.inspect}, Got: #{result.inspect}" if Tryouts.debug?
          all_passed = false
        end
      rescue StandardError => ex
        warn Console.color(:red, "Expectation evaluation failed: #{ex.message}")
        actual_results << "ERROR: #{ex.message}"
        all_passed = false
      end

      [all_passed, actual_results]
    end

    # Helper methods for verbose output
    def create_verbose_formatter
      source_lines = File.readlines(@testrun.source_file).map(&:chomp)
      VerboseFormatter.new(@testrun, source_lines)
    end

    def show_verbose_output?(test_result)
      return false unless @verbose
      return true unless @fails_only

      test_result == :failed
    end

    def show_verbose_output(result_data)
      formatter = create_verbose_formatter
      puts formatter.format_test_case(
        result_data[:test_case],
        result_data[:status],
        result_data[:actual_results],
      )
    end

    def handle_test_error(test_case, ex)
      if @verbose
        result_data = {
          test_case: test_case,
          status: :failed,
          actual_results: ["ERROR: #{ex.message}"],
        }
        show_verbose_output(result_data) if show_verbose_output?(:failed)
      else
        warn Console.color(:red, "Error in test: #{test_case.description}")
        warn Console.color(:red, ex.message)
        warn ex.backtrace.join($/), $/
      end
    end
  end
end
