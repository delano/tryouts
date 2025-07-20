# lib/tryouts/testbatch.rb

require 'stringio'

class Tryouts
  # Modern TestBatch using Ruby 3.4+ patterns and formatter system
  class TestBatch
    attr_reader :testrun, :failed_count, :container, :status, :results, :formatter, :output_manager

    def initialize(testrun, **options)
      @testrun         = testrun
      @container       = Object.new
      @options         = options
      @formatter       = Tryouts::CLI::FormatterFactory.create_formatter(options)
      @output_manager  = options[:output_manager]
      @global_tally    = options[:global_tally]
      @failed_count    = 0
      @status          = :pending
      @results         = []
      @start_time      = nil
      @test_case_count = 0
    end

    # Main execution pipeline using functional composition
    def run(before_test_hook = nil, &)
      return false if empty?

      @start_time      = Time.now
      @test_case_count = test_cases.size

      @output_manager&.execution_phase(@test_case_count)
      @output_manager&.info("Context: #{@options[:shared_context] ? 'shared' : 'fresh'}", 1)
      @output_manager&.file_start(path, context: @options[:shared_context] ? :shared : :fresh)

      if shared_context?
        @output_manager&.info('Running global setup...', 2)
        execute_global_setup
      end

      idx               = 0
      execution_results = test_cases.map do |test_case|
        @output_manager&.trace("Test #{idx + 1}/#{@test_case_count}: #{test_case.description}", 2)
        idx += 1

        @output_manager&.test_start(test_case, idx, @test_case_count)
        result = execute_single_test(test_case, before_test_hook, &) # runs the test code
        @output_manager&.test_end(test_case, idx, @test_case_count)

        result
      end

      # Used for a separate purpose then execution_phase.
      # e.g. the quiet formatter prints a newline after all test dots
      @output_manager&.file_end(path, context: @options[:shared_context] ? :shared : :fresh)

      @output_manager&.execution_phase(test_cases.size)

      execute_global_teardown
      finalize_results(execution_results)

      @status = :completed
      !failed?
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

    def failed?
      @failed_count > 0
    end

    def completed?
      @status == :completed
    end

    private

    # Pattern matching for execution strategy selection
    def execute_single_test(test_case, before_test_hook = nil)
      before_test_hook&.call(test_case)

      # Capture output during test execution
      result          = nil
      captured_output = capture_output do
        result = case @options[:shared_context]
                 when true
                   execute_with_shared_context(test_case)
                 when false, nil
                   execute_with_fresh_context(test_case)
                 else
                   raise 'Invalid execution context configuration'
                 end
      end

      # Add captured output to the result
      result[:captured_output] = captured_output if captured_output && !captured_output.empty?

      process_test_result(result)
      yield(test_case) if block_given?
      result
    end

    # Shared context execution - setup runs once, all tests share state
    def execute_with_shared_context(test_case)
      if test_case.exception_expectations?
        # For exception tests, don't execute code here - let evaluate_expectations handle it
        expectations_result = evaluate_expectations(test_case, nil, @container)
        build_test_result(test_case, nil, expectations_result)
      else
        # Regular execution for non-exception tests
        code  = test_case.code
        path  = test_case.path
        range = test_case.line_range

        result_value        = @container.instance_eval(code, path, range.first + 1)
        expectations_result = evaluate_expectations(test_case, result_value, @container)

        build_test_result(test_case, result_value, expectations_result)
      end
    rescue StandardError => ex
      build_error_result(test_case, ex.message, ex)
    end

    # Fresh context execution - setup runs per test, isolated state
    def execute_with_fresh_context(test_case)
      fresh_container = Object.new

      # Execute setup in fresh context if present
      setup = @testrun.setup
      if setup && !setup.code.empty?
        fresh_container.instance_eval(setup.code, setup.path, 1)
      end

      if test_case.exception_expectations?
        # For exception tests, don't execute code here - let evaluate_expectations handle it
        expectations_result = evaluate_expectations(test_case, nil, fresh_container)
        build_test_result(test_case, nil, expectations_result)
      else
        # Regular execution for non-exception tests
        code  = test_case.code
        path  = test_case.path
        range = test_case.line_range

        result_value        = fresh_container.instance_eval(code, path, range.first + 1)
        expectations_result = evaluate_expectations(test_case, result_value, fresh_container)

        build_test_result(test_case, result_value, expectations_result)
      end
    rescue StandardError => ex
      build_error_result(test_case, ex.message, ex)
    end

    # Evaluate expectations using pattern matching for clean result handling
    def evaluate_expectations(test_case, actual_result, context)
      if test_case.expectations.empty?
        { passed: true, actual_results: [], expected_results: [] }
      else
        # Handle exception expectations differently from regular expectations
        if test_case.exception_expectations?
          evaluate_exception_expectations(test_case, context)
        else
          evaluate_regular_expectations(test_case, actual_result, context)
        end
      end
    end

    def evaluate_regular_expectations(test_case, actual_result, context)
      evaluation_results = test_case.regular_expectations.map do |expectation|
        evaluate_single_expectation(expectation, actual_result, context, test_case)
      end

      {
        passed: evaluation_results.all? { |r| r[:passed] },
        actual_results: evaluation_results.map { |r| r[:actual] },
        expected_results: evaluation_results.map { |r| r[:expected] },
      }
    end

    def evaluate_exception_expectations(test_case, context)
      # For exception expectations, we need to execute the code and catch the exception
      begin
        # Execute the test code - this should raise an exception
        path = test_case.path
        range = test_case.line_range
        context.instance_eval(test_case.code, path, range.first + 1)

        # If we get here, no exception was raised - that's a failure
        {
          passed: false,
          actual_results: ["No exception was raised"],
          expected_results: test_case.exception_expectations.map(&:content),
        }
      rescue StandardError => error
        # Exception was caught - now evaluate the exception expectations
        evaluation_results = test_case.exception_expectations.map do |expectation|
          evaluate_exception_expectation(expectation, error, context, test_case)
        end

        {
          passed: evaluation_results.all? { |r| r[:passed] },
          actual_results: evaluation_results.map { |r| r[:actual] },
          expected_results: evaluation_results.map { |r| r[:expected] },
        }
      end
    end

    def evaluate_exception_expectation(expectation, caught_error, context, test_case)
      path = test_case.path
      range = test_case.line_range

      # Make the caught error available as 'error' in the expectation context
      context.define_singleton_method(:error) { caught_error }

      begin
        expected_value = context.instance_eval(expectation.content, path, range.first + 1)

        {
          passed: !!expected_value, # Convert to boolean
          actual: caught_error.message,
          expected: expectation.content,
          expectation: expectation.content,
        }
      rescue StandardError => ex
        {
          passed: false,
          actual: caught_error.message,
          expected: "EXPECTED: #{ex.message}",
          expectation: expectation.content,
        }
      end
    end

    def evaluate_single_expectation(expectation, actual_result, context, test_case)
      path  = test_case.path
      range = test_case.line_range

      expected_value = context.instance_eval(expectation.content, path, range.first + 1)

      {
        passed: actual_result == expected_value,
        actual: actual_result,
        expected: expected_value,
        expectation: expectation.content,
      }
    rescue StandardError => ex
      {
        passed: false,
        actual: actual_result,
        expected: "EXPECTED: #{ex.message}",
        expectation: expectation.content,
      }
    end

    # Build structured test results using pattern matching
    def build_test_result(test_case, result_value, expectations_result)
      if expectations_result[:passed]
        {
          test_case: test_case,
          status: :passed,
          result_value: result_value,
          actual_results: expectations_result[:actual_results],
          error: nil,
        }
      else
        {
          test_case: test_case,
          status: :failed,
          result_value: result_value,
          actual_results: expectations_result[:actual_results],
          error: nil,
        }
      end
    end

    def build_error_result(test_case, message, exception = nil)
      {
        test_case: test_case,
        status: :error,
        result_value: nil,
        actual_results: ["ACTUAL: #{message}"],
        error: exception,
      }
    end

    # Process and display test results using formatter
    def process_test_result(result)
      @results << result

      if [:failed, :error].include?(result[:status])
        @failed_count += 1
      end

      @output_manager&.file_start(path, context: @options[:shared_context] ? :shared : :fresh)

      show_test_result(result)

      # Show captured output if any exists
      if result[:captured_output] && !result[:captured_output].empty?
        @output_manager&.test_output(result[:test_case], result[:captured_output])
      end
    end

    # Global setup execution for shared context mode
    def execute_global_setup
      setup = @testrun.setup

      if setup && !setup.code.empty? && @options[:shared_context]
        @output_manager&.setup_start(setup.line_range)

        # Capture setup output instead of letting it print directly
        captured_output = capture_output do
          @container.instance_eval(setup.code, setup.path, setup.line_range.first + 1)
        end

        @output_manager&.setup_output(captured_output) if captured_output && !captured_output.empty?
      end
    rescue StandardError => ex
      @global_tally[:total_errors] += 1 if @global_tally
      Tryouts.trace "(#{ex.class}): #{ex.message}"
      Tryouts.trace ex.backtrace
      raise "Global setup failed (#{ex.class}): #{ex.message}"
    end

    # Global teardown execution
    def execute_global_teardown
      teardown = @testrun.teardown

      if teardown && !teardown.code.empty?
        @output_manager&.teardown_start(teardown.line_range)

        # Capture teardown output instead of letting it print directly
        captured_output = capture_output do
          @container.instance_eval(teardown.code, teardown.path, teardown.line_range.first + 1)
        end

        @output_manager&.teardown_output(captured_output) if captured_output && !captured_output.empty?
      end
    rescue StandardError => ex
      @global_tally[:total_errors] += 1 if @global_tally
      @output_manager&.error("Teardown failed: #{ex.message}")
    end

    # Result finalization and summary display
    def finalize_results(_execution_results)
      @status      = :completed
      elapsed_time = Time.now - @start_time
      show_summary(elapsed_time)
    end

    def show_test_result(result)
      test_case = result[:test_case]
      status    = result[:status]
      actuals   = result[:actual_results]

      @output_manager&.test_result(test_case, status, actuals)
    end

    def show_summary(elapsed_time)
      @output_manager&.batch_summary(size, @failed_count, elapsed_time)
    end

    # Helper methods using pattern matching

    def shared_context?
      @options[:shared_context] == true
    end

    def capture_output
      old_stdout = $stdout
      old_stderr = $stderr
      $stdout    = StringIO.new
      $stderr    = StringIO.new

      yield

      captured = $stdout.string + $stderr.string
      captured.empty? ? nil : captured
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    def handle_batch_error(exception)
      @status       = :error
      @failed_count = 1

      error_message = "Batch execution failed: #{exception.message}"
      backtrace     = exception.respond_to?(:backtrace) ? exception.backtrace : nil

      @output_manager&.error(error_message, backtrace)
    end
  end
end
