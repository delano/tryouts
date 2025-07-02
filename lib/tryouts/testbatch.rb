# lib/tryouts/testbatch.rb

class Tryouts
  # Modern TestBatch using Ruby 3.4+ patterns and formatter system
  class TestBatch
    attr_reader :testrun, :failed_count, :container, :status, :results, :formatter

    def initialize(testrun, **options)
      Tryouts.debug "TestBatch#initialize: Initializing with options: #{options.inspect}"
      @testrun      = testrun
      @container    = Object.new
      @options      = options
      @formatter    = Tryouts::CLI::FormatterFactory.create(options)
      @failed_count = 0
      @status       = :pending
      @results      = []
      @start_time   = nil
    end

    # Main execution pipeline using functional composition
    def run(before_test_hook = nil, &)
      Tryouts.debug "TestBatch#run: Starting test run for #{@testrun.source_file}"
      if empty?
        Tryouts.debug 'TestBatch#run: No test cases found, skipping run.'
        return false
      end

      @start_time = Time.now

      begin
        Tryouts.debug 'TestBatch#run: Showing file header.'
        show_file_header
        if shared_context?
          Tryouts.debug 'TestBatch#run: Executing global setup (shared context).'
          execute_global_setup
        end

        Tryouts.debug "TestBatch#run: Executing test cases (#{test_cases.size} total)."
        execution_results = test_cases.map do |test_case|
          execute_single_test(test_case, before_test_hook, &)
        end
        Tryouts.debug 'TestBatch#run: All test cases executed.'

        Tryouts.debug 'TestBatch#run: Executing global teardown.'
        execute_global_teardown
        Tryouts.debug 'TestBatch#run: Finalizing results.'
        finalize_results(execution_results)

        @status = :completed
        Tryouts.debug "TestBatch#run: Test run completed. Status: #{@status}, Failed: #{failed?}"
        !failed?
      rescue StandardError => ex
        Tryouts.debug "TestBatch#run: An error occurred during batch execution: #{ex.message}"
        handle_batch_error(ex)
        false
      end
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
      Tryouts.debug "TestBatch#execute_single_test: Running test case: #{test_case.description}"
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
      Tryouts.debug "TestBatch#process_test_result: Processing result for #{result[:test_case].description}, status: #{result[:status]}"
      @results << result

      if [:failed, :error].include?(result[:status])
        @failed_count += 1
      end

      show_test_result(result) if should_show_result?(result)
    end

    # Global setup execution for shared context mode
    def execute_global_setup
      Tryouts.debug 'TestBatch#execute_global_setup: Checking for global setup.'
      setup = @testrun.setup

      if setup && !setup.code.empty? && @options[:shared_context]
        Tryouts.debug "TestBatch#execute_global_setup: Executing global setup code (length: #{setup.code.length})."
        @container.instance_eval(setup.code, setup.path, setup.line_range.first + 1)
      else
        Tryouts.debug 'TestBatch#execute_global_setup: No global setup code to execute or not in shared context.'
      end
    rescue StandardError => ex
      Tryouts.debug "TestBatch#execute_global_setup: Global setup failed with error: #{ex.message}"
      raise "Global setup failed: #{ex.message}"
    end

    # Global teardown execution
    def execute_global_teardown
      Tryouts.debug 'TestBatch#execute_global_teardown: Checking for global teardown.'
      teardown = @testrun.teardown

      if teardown && !teardown.code.empty?
        Tryouts.debug "TestBatch#execute_global_teardown: Teardown detected, code length: #{teardown.code.length}"
        @container.instance_eval(teardown.code, teardown.path, teardown.line_range.first + 1)
      else
        Tryouts.debug 'TestBatch#execute_global_teardown: No teardown code detected.'
      end
    rescue StandardError => ex
      Tryouts.debug "TestBatch#execute_global_teardown: Teardown failed with error: #{ex.message}"
      warn Console.color(:red, "Teardown failed: #{ex.message}")
    end

    # Result finalization and summary display
    def finalize_results(_execution_results)
      @status      = :completed
      elapsed_time = Time.now - @start_time
      show_summary(elapsed_time)
    end

    # Display methods using formatter system
    def show_file_header
      Tryouts.debug "TestBatch#show_file_header: Formatting and displaying file header for #{@testrun.source_file}."
      header = @formatter.format_file_header(@testrun)
      puts header unless header.empty?
    end

    def show_test_result(result)
      Tryouts.debug "TestBatch#show_test_result: Formatting and displaying result for #{result[:test_case].description}, status: #{result[:status]}."
      test_case = result[:test_case]
      status    = result[:status]
      actuals   = result[:actual_results]

      output = @formatter.format_test_result(test_case, status, actuals)
      puts output unless output.empty?
    end

    def show_summary(elapsed_time)
      Tryouts.debug "TestBatch#show_summary: Formatting and displaying summary. Total: #{size}, Failed: #{@failed_count}, Elapsed: #{elapsed_time}s."
      summary = @formatter.format_summary(size, @failed_count, elapsed_time)
      puts summary unless summary.empty?
    end

    # Helper methods using pattern matching
    def should_show_result?(result)
      verbose    = @options[:verbose]
      fails_only = @options[:fails_only] == true  # Convert to proper boolean
      status     = result[:status]

      # rubocop:disable Lint/DuplicateBranch
      #
      # NOTE: Do not fix rubocop.
      #
      # I find the vertical alignment of the case in more readable than the
      # default Rubocop preference which suggests combining into a single line:
      #
      #   in [true, true, :failed | :error] | [true, false, _] | [false, _, _]
      #
      case [verbose, fails_only, status]
      when [true, true, :failed], [true, true, :error]
        true
      when [true, false], [false]
        true
      else
        false
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    def shared_context?
      @options[:shared_context] == true
    end

    def handle_batch_error(exception)
      @status       = :error
      @failed_count = 1

      error_message = "Batch execution failed: #{exception.message}"

      warn Console.color(:red, error_message)
      warn exception.backtrace.join($/), $/ if exception.respond_to?(:backtrace)
    end
  end
end
