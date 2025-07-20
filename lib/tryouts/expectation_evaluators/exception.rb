# lib/tryouts/expectation_evaluators/exception.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Exception < Base
      def self.handles?(expectation_type)
        expectation_type == :exception
      end

      def evaluate(_actual_result = nil)
        execute_test_code_and_evaluate_exception
      end

      private

      def execute_test_code_and_evaluate_exception
        path  = @test_case.path
        range = @test_case.line_range
        @context.instance_eval(@test_case.code, path, range.first + 1)

        build_result(
          passed: false,
          actual: 'No exception was raised',
          expected: @expectation.content,
        )
      rescue StandardError => ex
        evaluate_exception_condition(ex)
      end

      def evaluate_exception_condition(caught_error)
        @context.define_singleton_method(:error) { caught_error }

        expected_value = eval_expectation_content(@expectation.content, caught_error)

        build_result(
          passed: !!expected_value,
          actual: caught_error.message,
          expected: @expectation.content,
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
