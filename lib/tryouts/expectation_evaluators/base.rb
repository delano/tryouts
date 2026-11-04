# lib/tryouts/expectation_evaluators/base.rb
#
# frozen_string_literal: true

class Tryouts
  module ExpectationEvaluators
    # Base class for all expectation evaluators.
    #
    # An evaluator gets the expectation, the test case and an EvaluationContext.
    # The test code has already run, once, by the time #evaluate is called;
    # an evaluator never runs it again. It evaluates the expression after the
    # arrow with #evaluate_expression, which compiles it into the test's own
    # binding (see EvaluationContext), and returns a result hash built with
    # #build_result.
    #
    # VARIABLE AVAILABILITY (in every expectation expression):
    # - the test's local variables, instance variables and constants
    # - `result` / `_`: the value of the test's last statement, or the
    #   exception it raised when the test was allowed to raise
    # - `error`: the exception the test raised, or nil
    # - `elapsed_ms`: how long the test code took, in milliseconds
    #
    # #evaluate receives the same value as `result` in actual_result.
    class Base
      attr_reader :expectation, :test_case, :context

      # @param expectation_type [Symbol]
      # @return [Boolean] whether this evaluator handles the expectation type
      def self.handles?(expectation_type)
        raise NotImplementedError, "#{self} must implement handles? class method"
      end

      # @param expectation [Expectation, OutputExpectation]
      # @param test_case [TestCase]
      # @param context [EvaluationContext]
      def initialize(expectation, test_case, context)
        @expectation = expectation
        @test_case   = test_case
        @context     = context
      end

      # @param actual_result [Object] the value under test
      # @return [Hash] :passed, :actual, :expected, :expectation, and :error
      def evaluate(actual_result = nil)
        raise NotImplementedError, "#{self.class} must implement evaluate method"
      end

      protected

      # Evaluate the expression after the arrow, at the expectation's own line.
      def evaluate_expression(content = @expectation.content)
        @context.evaluate(content, expectation_line)
      end

      # 1-based line of this expectation in the source file.
      def expectation_line
        line = @expectation.line || @test_case.first_expectation_line || @test_case.line_range.first
        line + 1
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
          expected: EvaluationError.new(message: error.message),
          expectation: @expectation.content,
          error: error,
        )
      end
    end
  end
end
