# lib/tryouts/expectation_evaluators/base.rb

class Tryouts
  module ExpectationEvaluators
    class Base
      attr_reader :expectation, :test_case, :context

      def self.handles?(expectation_type)
        raise NotImplementedError, "#{self} must implement handles? class method"
      end

      def initialize(expectation, test_case, context)
        @expectation = expectation
        @test_case   = test_case
        @context     = context
      end

      def evaluate(actual_result = nil)
        raise NotImplementedError, "#{self.class} must implement evaluate method"
      end

      protected

      def eval_expectation_content(content)
        path  = @test_case.path
        range = @test_case.line_range
        @context.instance_eval(content, path, range.first + 1)
      end

      def build_result(passed:, actual:, expected:, expectation: @expectation.content, error: nil)
        result         = {
          passed: passed,
          actual: actual,
          expected: expected,
          expectation: expectation,
        }
        result[:error] = error if error
        result
      end

      def handle_evaluation_error(error, actual_result)
        build_result(
          passed: false,
          actual: actual_result,
          expected: "EXPECTED: #{error.message}",
          expectation: @expectation.content,
          error: error,
        )
      end
    end
  end
end
