# lib/tryouts/testbatch.rb

require 'stringio'

class Tryouts
  # Modern TestBatch using Ruby 3.4+ patterns and formatter system
  class TestBatch
    attr_reader :testrun, :failed_count, :container, :status, :results, :formatter, :output_manager

    def initialize(testrun, **options)
      @testrun        = testrun
      @container      = Object.new
      @options        = options
      @formatter      = Tryouts::CLI::FormatterFactory.create_formatter(options)
      @output_manager = options[:output_manager]
      @failed_count   = 0
      @status         = :pending
      @results        = []
      @start_time     = nil
    end

    # Main execution pipeline using functional composition
    def run(before_test_hook = nil, &)
      return false if empty?

      @start_time = Time.now
      @output_manager&.execution_phase(test_cases.size)
      @output_manager&.info("Context: #{@options[:shared_context] ? 'shared' : 'fresh'}", 1)
      @output_manager&.file_start(path, context: @options[:shared_context] ? :shared : :fresh)

      # begin
      show_file_header

      if shared_context?
        @output_manager&.info('Running global setup...', 2)
        execute_global_setup
      end

      idx               = 0
      execution_results = test_cases.map do |test_case|
        @output_manager&.trace("Test #{idx + 1}/#{test_cases.size}: #{test_case.description}", 2)
        idx += 1
        execute_single_test(test_case, before_test_hook, &)
      end

      execute_global_teardown
      finalize_results(execution_results)

      @status = :completed
      !failed?
      # rescue StandardError => ex
      #   Tryouts.debug "TestBatch#run: An error occurred during batch execution: #{ex.message}"
      #   handle_batch_error(ex)
      #   false
      # end
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

      result = case @options[:shared_context]
               when true
                 execute_with_shared_context(test_case)
               when false, nil
                 execute_with_fresh_context(test_case)
               else
                 raise 'Invalid execution context configuration'
               end

      process_test_result(result)
      yield(test_case) if block_given?
      result
    end

    # Shared context execution - setup runs once, all tests share state
    def execute_with_shared_context(test_case)
      code  = test_case.code
      path  = test_case.path
      range = test_case.line_range

      result_value        = @container.instance_eval(code, path, range.first + 1)
      expectations_result = evaluate_expectations(test_case, result_value, @container)

      build_test_result(test_case, result_value, expectations_result)
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

      # Execute test in same fresh context
      code  = test_case.code
      path  = test_case.path
      range = test_case.line_range

      result_value        = fresh_container.instance_eval(code, path, range.first + 1)
      expectations_result = evaluate_expectations(test_case, result_value, fresh_container)

      build_test_result(test_case, result_value, expectations_result)
    rescue StandardError => ex
      build_error_result(test_case, ex.message, ex)
    end

    # Evaluate expectations using pattern matching for clean result handling
    def evaluate_expectations(test_case, actual_result, context)
      if test_case.expectations.empty?
        { passed: true, actual_results: [], expected_results: [] }
      else
        evaluation_results = test_case.expectations.map do |expectation|
          evaluate_single_expectation(expectation, actual_result, context, test_case)
        end

        {
          passed: evaluation_results.all? { |r| r[:passed] },
          actual_results: evaluation_results.map { |r| r[:actual] },
          expected_results: evaluation_results.map { |r| r[:expected] },
        }
      end
    end

    def evaluate_single_expectation(expectation, actual_result, context, test_case)
      path  = test_case.path
      range = test_case.line_range

      expected_value = context.instance_eval(expectation, path, range.first + 1)

      {
        passed: actual_result == expected_value,
        actual: actual_result,
        expected: expected_value,
        expectation: expectation,
      }
    rescue StandardError => ex
      {
        passed: false,
        actual: actual_result,
        expected: "ERROR: #{ex.message}",
        expectation: expectation,
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
        actual_results: ["ERROR: #{message}"],
        error: exception,
      }
    end

    # Process and display test results using formatter
    def process_test_result(result)
      @results << result

      if [:failed, :error].include?(result[:status])
        @failed_count += 1
      end

      show_test_result(result) if should_show_result?(result)
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
      raise "Global setup failed: #{ex.message}"
    end

    # Global teardown execution
    def execute_global_teardown
      teardown = @testrun.teardown

      if teardown && !teardown.code.empty?
        @output_manager&.teardown_start(teardown.line_range)
        @container.instance_eval(teardown.code, teardown.path, teardown.line_range.first + 1)
      end
    rescue StandardError => ex
      @output_manager&.error("Teardown failed: #{ex.message}")
    end

    # Result finalization and summary display
    def finalize_results(_execution_results)
      @status      = :completed
      elapsed_time = Time.now - @start_time
      show_summary(elapsed_time)
    end

    # Display methods using formatter system
    def show_file_header
      # File header is now handled by output_manager in the run method
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
    def should_show_result?(result)
      verbose    = @options[:verbose]
      fails_only = @options[:fails_only] == true  # Convert to proper boolean
      status     = result[:status]

      case [verbose, fails_only, status]
      when [true, true, :failed], [true, true, :error]
        true
      when [true, false, :passed], [true, false, :failed], [true, false, :error]
        true
      when [false, false, :passed], [false, false, :failed], [false, false, :error]
        true
      else
        false
      end
    end

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
      backtrace     = exception.respond_to?(:backtrace) ? exception.backtrace.join($/) : nil

      @output_manager&.error(error_message, backtrace)
    end
  end
end
