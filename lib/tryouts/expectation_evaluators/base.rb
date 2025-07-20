# lib/tryouts/expectation_evaluators/base.rb

class Tryouts
  module ExpectationEvaluators
    # Base class for all expectation evaluators
    class Base
      attr_reader :expectation, :test_case, :context

      # @param expectation_type [Symbol] the type of expectation to check
      # @return [Boolean] whether this evaluator can handle the given expectation type
      def self.handles?(expectation_type)
        raise NotImplementedError, "#{self} must implement handles? class method"
      end

      # @param expectation [Object] the expectation object containing content and metadata
      # @param test_case [Object] the test case being evaluated
      # @param context [Object] the context in which to evaluate expectations
      def initialize(expectation, test_case, context)
        @expectation = expectation
        @test_case   = test_case
        @context     = context
      end

      # Evaluates the expectation against the actual result
      # @param actual_result [Object] the result to evaluate against the expectation
      # @return [Hash] evaluation result with passed status and details
      def evaluate(actual_result = nil)
        raise NotImplementedError, "#{self.class} must implement evaluate method"
      end

      protected

      # Evaluates expectation content in the test context with predefined variables
      #
      # This method defines the variables that expectations can access:
      # - `result`: contains the actual_result if provided
      # - `_`: shorthand alias for actual_result if provided
      #
      # @param content [String] the expectation code to evaluate
      # @param actual_result [Object] the result to make available as 'result' and '_' variables
      # @return [Object] the result of evaluating the content
      def eval_expectation_content(content, actual_result = nil)
        path  = @test_case.path
        range = @test_case.line_range

        # Make actual result available as 'result' and '_' variables if provided
        if actual_result
          @context.define_singleton_method(:result) { actual_result }
          @context.define_singleton_method(:_) { actual_result }
        end

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
