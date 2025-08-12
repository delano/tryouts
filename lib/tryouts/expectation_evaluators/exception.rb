# lib/tryouts/expectation_evaluators/exception.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Exception < Base
      def self.handles?(expectation_type)
        expectation_type == :exception
      end

      def evaluate(_actual_result = nil, caught_exception: nil)
        if caught_exception
          # Use the pre-caught exception to avoid double execution
          evaluate_exception_condition(caught_exception)
        else
          # Fallback for direct calls - shouldn't happen in normal flow
          execute_test_code_and_evaluate_exception
        end
      end

      private

      def execute_test_code_and_evaluate_exception
        path  = @test_case.path
        range = @test_case.line_range
        @context.instance_eval(@test_case.code, path, range.first + 1)

        # Create result packet for evaluation to show what was expected
        expectation_result = ExpectationResult.from_result(nil)
        expected_value     = eval_expectation_content(@expectation.content, expectation_result)

        build_result(
          passed: false,
          actual: 'No exception was raised',
          expected: expected_value,
        )
      rescue SystemStackError, NoMemoryError, SecurityError, ScriptError => ex
        # Handle system-level exceptions that don't inherit from StandardError
        # ScriptError includes: LoadError, SyntaxError, NotImplementedError
        evaluate_exception_condition(ex)
      rescue StandardError => ex
        evaluate_exception_condition(ex)
      end

      def evaluate_exception_condition(caught_error)
        @context.define_singleton_method(:error) { caught_error }

        expectation_result = ExpectationResult.from_result(caught_error)
        expected_value     = eval_expectation_content(@expectation.content, expectation_result)

        build_result(
          passed: !!expected_value,
          actual: caught_error.message,
          expected: expected_value,
        )
      rescue StandardError => ex
        build_result(
          passed: false,
          actual: caught_error.message,
          expected: "EXPECTED: #{ex.message}",
          error: ex,
        )
      end
    end
  end
end
