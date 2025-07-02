# lib/tryouts/testbatch.rb

require_relative 'formatters'

class Tryouts
  # Modern TestBatch using Ruby 3.4+ patterns and formatter system
  class TestBatch
    attr_reader :testrun, :failed_count, :container, :status, :results, :formatter

    def initialize(testrun, **options)
      @testrun      = testrun
      @container    = Object.new
      @options      = options
      @formatter    = FormatterFactory.create(options)
      @failed_count = 0
      @status       = :pending
      @results      = []
      @start_time   = nil
    end

    # Main execution pipeline using functional composition
    def run(before_test_hook = nil, &)
      return false if empty?

      @start_time = Time.now

      begin
        show_file_header
        execute_global_setup if shared_context?

        execution_results = test_cases.map do |test_case|
          execute_single_test(test_case, before_test_hook, &)
        end

        execute_global_teardown
        finalize_results(execution_results)

        !failed?
      rescue StandardError => ex
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
      before_test_hook&.call(test_case)

      result = case @options[:shared_context]
               in true
                 execute_with_shared_context(test_case)
               in false | nil
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
      case test_case
      in { code: String => code, path: String => path, line_range: Range => range }
        result_value        = @container.instance_eval(code, path, range.first + 1)
        expectations_result = evaluate_expectations(test_case, result_value, @container)

        build_test_result(test_case, result_value, expectations_result)
      else
        build_error_result(test_case, 'Invalid test case structure')
      end
    rescue StandardError => ex
      build_error_result(test_case, ex.message, ex)
    end

    # Fresh context execution - setup runs per test, isolated state
    def execute_with_fresh_context(test_case)
      fresh_container = Object.new

      case [@testrun.setup, test_case]
      in [{ code: String => setup_code, path: String => setup_path }, test_case]
        # Execute setup in fresh context
        fresh_container.instance_eval(setup_code, setup_path, 1) unless setup_code.empty?

        # Execute test in same fresh context
        case test_case
        in { code: String => code, path: String => path, line_range: Range => range }
          result_value        = fresh_container.instance_eval(code, path, range.first + 1)
          expectations_result = evaluate_expectations(test_case, result_value, fresh_container)

          build_test_result(test_case, result_value, expectations_result)
        end
      else
        build_error_result(test_case, 'Invalid setup or test case structure')
      end
    rescue StandardError => ex
      build_error_result(test_case, ex.message, ex)
    end

    # Evaluate expectations using pattern matching for clean result handling
    def evaluate_expectations(test_case, actual_result, context)
      case test_case.expectations
      in []
        { passed: true, actual_results: [], expected_results: [] }
      in Array => expectations
        evaluation_results = expectations.map do |expectation|
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
      case test_case
      in { path: String => path, line_range: Range => range }
        expected_value = context.instance_eval(expectation, path, range.first + 1)

        {
          passed: actual_result == expected_value,
          actual: actual_result,
          expected: expected_value,
          expectation: expectation,
        }
      end
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
      case expectations_result
      in { passed: true, actual_results: Array => actuals }
        {
          test_case: test_case,
          status: :passed,
          result_value: result_value,
          actual_results: actuals,
          error: nil,
        }
      in { passed: false, actual_results: Array => actuals }
        {
          test_case: test_case,
          status: :failed,
          result_value: result_value,
          actual_results: actuals,
          error: nil,
        }
      else
        build_error_result(test_case, 'Invalid expectations result structure')
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

      case result
      in { status: :failed | :error }
        @failed_count += 1
      else
        # Handle :passed and other statuses - no failed count increment needed
      end

      show_test_result(result) if should_show_result?(result)
    end

    # Global setup execution for shared context mode
    def execute_global_setup
      case [@testrun.setup, @options[:shared_context]]
      in [{ code: String => code, path: String => path, line_range: Range => range }, true]
        @container.instance_eval(code, path, range.first + 1) unless code.empty?
      end
    rescue StandardError => ex
      raise "Global setup failed: #{ex.message}"
    end

    # Global teardown execution
    def execute_global_teardown
      case @testrun.teardown
      in { code: String => code, path: String => path, line_range: Range => range }
        puts "DEBUG: Teardown detected, code length: #{code.length}" if ENV['DEBUG']
        puts "DEBUG: Teardown code:\n#{code}" if ENV['DEBUG']
        @container.instance_eval(code, path, range.first + 1) unless code.empty?
      else
        puts 'DEBUG: No teardown code detected' if ENV['DEBUG']
      end
    rescue StandardError => ex
      warn Console.color(:red, "Teardown failed: #{ex.message}")
      puts "DEBUG: Teardown code was: #{@testrun.teardown&.code || 'nil'}" if ENV['DEBUG']
    end

    # Result finalization and summary display
    def finalize_results(_execution_results)
      @status      = :completed
      elapsed_time = Time.now - @start_time
      show_summary(elapsed_time)
    end

    # Display methods using formatter system
    def show_file_header
      header = @formatter.format_file_header(@testrun)
      puts header unless header.empty?
    end

    def show_test_result(result)
      case result
      in { test_case: test_case, status: status, actual_results: actuals }
        output = @formatter.format_test_result(test_case, status, actuals)
        puts output unless output.empty?
      end
    end

    def show_summary(elapsed_time)
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
      # I find the vertical alignment of the case in more readable than the
      # default Rubocop preference which suggests combining into a single line:
      #
      #   in [true, true, :failed | :error] | [true, false, _] | [false, _, _]
      #
      case [verbose, fails_only, status]
      in [true, true, :failed | :error]
        true
      in [true, false, _] | [false, _, _]
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

      error_message = case exception
                      in StandardError => ex
                        "Batch execution failed: #{ex.message}"
                      else
                        'Unknown batch execution error'
                      end

      warn Console.color(:red, error_message)
      warn exception.backtrace.join($/), $/ if exception.respond_to?(:backtrace)
    end
  end
end
