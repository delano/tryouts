# lib/tryouts/testbatch.rb

require 'stringio'
require_relative 'expectation_evaluators/registry'

class Tryouts
  # Factory for creating fresh context containers for each test
  class FreshContextFactory
    def initialize
      @containers_created = 0
    end

    def create_container
      @containers_created += 1
      Object.new
    end

    def containers_created_count
      @containers_created
    end
  end

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
      @setup_failed    = false

      # Circuit breaker for batch-level failure protection
      @consecutive_failures = 0
      @max_consecutive_failures = options[:max_consecutive_failures] || 10
      @circuit_breaker_active = false

      # Expose context objects for testing - different strategies for each mode
      @shared_context = if options[:shared_context]
                          @container  # Shared mode: single container reused across tests
                        else
                          FreshContextFactory.new  # Fresh mode: factory that creates new containers
                        end
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

        # Stop execution if setup failed
        if @setup_failed
          @output_manager&.error("Stopping batch execution due to setup failure")
          @status = :failed
          finalize_results([])
          return false
        end
      end

      idx               = 0
      execution_results = test_cases.map do |test_case|
        @output_manager&.trace("Test #{idx + 1}/#{@test_case_count}: #{test_case.description}", 2)
        idx += 1

        # Check circuit breaker before executing test
        if @circuit_breaker_active
          @output_manager&.error("Circuit breaker active - skipping remaining tests after #{@consecutive_failures} consecutive failures")
          break
        end

        @output_manager&.test_start(test_case, idx, @test_case_count)
        result = execute_single_test(test_case, before_test_hook, &) # runs the test code
        @output_manager&.test_end(test_case, idx, @test_case_count)

        # Update circuit breaker state based on result
        update_circuit_breaker(result)

        result
      rescue StandardError => e
        @output_manager&.test_end(test_case, idx, @test_case_count, status: :failed, error: e)
        # Create error result packet to maintain consistent data flow
        error_result = build_error_result(test_case, e)
        process_test_result(error_result)

        # Update circuit breaker for exception cases
        update_circuit_breaker(error_result)

        error_result
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

      # Add captured output to the result if any exists
      if captured_output && !captured_output.empty?
        # Create new result packet with captured output
        result = result.class.new(
          test_case: result.test_case,
          status: result.status,
          result_value: result.result_value,
          actual_results: result.actual_results,
          expected_results: result.expected_results,
          error: result.error,
          captured_output: captured_output,
          elapsed_time: result.elapsed_time,
          metadata: result.metadata
        )
      end

      process_test_result(result)
      yield(test_case) if block_given?
      result
    end

    # Shared context execution - setup runs once, all tests share state
    def execute_with_shared_context(test_case)
      execute_test_case_with_container(test_case, @container)
    end

    # Fresh context execution - setup runs per test, isolated state
    def execute_with_fresh_context(test_case)
      fresh_container = if @shared_context.is_a?(FreshContextFactory)
                          @shared_context.create_container
                        else
                          Object.new  # Fallback for backwards compatibility
                        end

      # Execute setup in fresh context if present
      setup = @testrun.setup
      if setup && !setup.code.empty?
        fresh_container.instance_eval(setup.code, setup.path, 1)
      end

      execute_test_case_with_container(test_case, fresh_container)
    end

    # Common test execution logic shared by both context modes
    def execute_test_case_with_container(test_case, container)
      # Individual test timeout protection
      test_timeout = @options[:test_timeout] || 30 # 30 second default

      if test_case.exception_expectations?
        # For exception tests, don't execute code here - let evaluate_expectations handle it
        expectations_result = execute_with_timeout(test_timeout, test_case) do
          evaluate_expectations(test_case, nil, container)
        end
        build_test_result(test_case, nil, expectations_result)
      else
        # Regular execution for non-exception tests with timing and output capture
        code  = test_case.code
        path  = test_case.path
        range = test_case.line_range

        # Check if we need output capture for any expectations
        needs_output_capture = test_case.expectations.any?(&:output?)

        result_value, execution_time_ns, stdout_content, stderr_content, expectations_result =
          execute_with_timeout(test_timeout, test_case) do
            if needs_output_capture
              # Execute with output capture using Fiber-local isolation
              result_value, execution_time_ns, stdout_content, stderr_content =
                execute_with_output_capture(container, code, path, range)

              expectations_result = evaluate_expectations(
                test_case, result_value, container, execution_time_ns, stdout_content, stderr_content
              )
              [result_value, execution_time_ns, stdout_content, stderr_content, expectations_result]
            else
              # Regular execution with timing capture only
              execution_start_ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
              result_value = container.instance_eval(code, path, range.first + 1)
              execution_end_ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
              execution_time_ns = execution_end_ns - execution_start_ns

              expectations_result = evaluate_expectations(test_case, result_value, container, execution_time_ns)
              [result_value, execution_time_ns, nil, nil, expectations_result]
            end
          end

        build_test_result(test_case, result_value, expectations_result)
      end
    rescue StandardError => ex
      build_error_result(test_case, ex)
    rescue SystemExit, SignalException => ex
      # Handle process control exceptions gracefully
      Tryouts.debug "Test received #{ex.class}: #{ex.message}"
      build_error_result(test_case, StandardError.new("Test terminated by #{ex.class}: #{ex.message}"))
    end

    # Execute test code with Fiber-based stdout/stderr capture
    def execute_with_output_capture(container, code, path, range)
      # Fiber-local storage for output redirection
      original_stdout = $stdout
      original_stderr = $stderr

      # Create StringIO objects for capturing output
      captured_stdout = StringIO.new
      captured_stderr = StringIO.new

      begin
        # Redirect output streams using Fiber-local variables
        Fiber.new do
          $stdout = captured_stdout
          $stderr = captured_stderr

          # Execute with timing capture
          execution_start_ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
          result_value = container.instance_eval(code, path, range.first + 1)
          execution_end_ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
          execution_time_ns = execution_end_ns - execution_start_ns

          [result_value, execution_time_ns]
        end.resume.tap do |result_value, execution_time_ns|
          # Return captured content along with result
          return [result_value, execution_time_ns, captured_stdout.string, captured_stderr.string]
        end
      ensure
        # Always restore original streams
        $stdout = original_stdout
        $stderr = original_stderr
      end
    end

    # Evaluate expectations using new object-oriented evaluation system
    def evaluate_expectations(test_case, actual_result, context, execution_time_ns = nil, stdout_content = nil, stderr_content = nil)
      return { passed: true, actual_results: [], expected_results: [] } if test_case.expectations.empty?

      evaluation_results = test_case.expectations.map do |expectation|
        evaluator = ExpectationEvaluators::Registry.evaluator_for(expectation, test_case, context)

        # Pass appropriate data to different evaluator types
        if expectation.performance_time? && execution_time_ns
          evaluator.evaluate(actual_result, execution_time_ns)
        elsif expectation.output? && (stdout_content || stderr_content)
          evaluator.evaluate(actual_result, stdout_content, stderr_content)
        else
          evaluator.evaluate(actual_result)
        end
      end

      aggregate_evaluation_results(evaluation_results)
    end

    # Aggregate individual evaluation results into the expected format
    def aggregate_evaluation_results(evaluation_results)
      {
        passed: evaluation_results.all? { |r| r[:passed] },
        actual_results: evaluation_results.map { |r| r[:actual] },
        expected_results: evaluation_results.map { |r| r[:expected] }
      }
    end

    # Build structured test results using TestCaseResultPacket
    def build_test_result(test_case, result_value, expectations_result)
      if expectations_result[:passed]
        TestCaseResultPacket.from_success(
          test_case,
          result_value,
          expectations_result[:actual_results],
          expectations_result[:expected_results]
        )
      else
        TestCaseResultPacket.from_failure(
          test_case,
          result_value,
          expectations_result[:actual_results],
          expectations_result[:expected_results]
        )
      end
    end

    def build_error_result(test_case, exception)
      TestCaseResultPacket.from_error(test_case, exception)
    end

    # Process and display test results using formatter
    def process_test_result(result)
      @results << result

      if result.failed? || result.error?
        @failed_count += 1
      end

      show_test_result(result)

      # Show captured output if any exists
      if result.has_output?
        @output_manager&.test_output(result.test_case, result.captured_output)
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
      @setup_failed = true
      @global_tally[:total_errors] += 1 if @global_tally

      # Classify error and handle appropriately
      error_type = Tryouts.classify_error(ex)

      Tryouts.debug "Setup failed with #{error_type} error: (#{ex.class}): #{ex.message}"
      Tryouts.trace ex.backtrace

      # For non-catastrophic errors, we still stop batch execution
      unless Tryouts.batch_stopping_error?(ex)
        @output_manager&.error("Global setup failed: #{ex.message}")
        return
      end

      # For catastrophic errors, still raise to stop execution
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

      # Classify error and handle appropriately
      error_type = Tryouts.classify_error(ex)

      Tryouts.debug "Teardown failed with #{error_type} error: (#{ex.class}): #{ex.message}"
      Tryouts.trace ex.backtrace

      @output_manager&.error("Teardown failed: #{ex.message}")

      # Teardown failures are generally non-fatal - log and continue
      unless Tryouts.batch_stopping_error?(ex)
        @output_manager&.error("Continuing despite teardown failure")
      else
        # Only catastrophic errors should potentially affect batch completion
        @output_manager&.error("Teardown failure may affect subsequent operations")
      end
    end

    # Result finalization and summary display
    def finalize_results(_execution_results)
      @status      = :completed
      elapsed_time = Time.now - @start_time
      show_summary(elapsed_time)
    end

    def show_test_result(result)
      @output_manager&.test_result(result)
    end

    def show_summary(elapsed_time)
      # Use actual executed test count, not total tests in file
      executed_count = @results.size
      @output_manager&.batch_summary(executed_count, @failed_count, elapsed_time)
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

    # Timeout protection for individual test execution
    def execute_with_timeout(timeout_seconds, test_case)
      Timeout.timeout(timeout_seconds) do
        yield
      end
    rescue Timeout::Error => e
      Tryouts.debug "Test timeout after #{timeout_seconds}s: #{test_case.description}"
      raise StandardError.new("Test execution timeout (#{timeout_seconds}s)")
    end

    # Circuit breaker pattern for batch-level failure protection
    def update_circuit_breaker(result)
      if result.failed? || result.error?
        @consecutive_failures += 1
        if @consecutive_failures >= @max_consecutive_failures
          @circuit_breaker_active = true
          Tryouts.debug "Circuit breaker activated after #{@consecutive_failures} consecutive failures"
        end
      else
        # Reset on success
        @consecutive_failures = 0
        @circuit_breaker_active = false
      end
    end
  end
end
