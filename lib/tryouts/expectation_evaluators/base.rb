# lib/tryouts/expectation_evaluators/base.rb
#
# frozen_string_literal: true

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
      # This method is the core of the expectation evaluation system, providing context-aware
      # variable access for different expectation types:
      #
      # VARIABLE AVAILABILITY:
      # - `result`: contains actual_result (regular) or timing_ms (performance)
      # - `_`: shorthand alias for the same data as result
      #
      # DESIGN DECISIONS:
      # - Add new values to ExpectationResult to avoid method signature changes
      # - Use define_singleton_method for clean variable injection
      # - Using instance_eval for evaluation provides:
      #     - Full access to test context (instance variables, methods)
      #     - Clean variable injection (result, _)
      #     - Proper file/line reporting for debugging
      #     - Support for complex Ruby expressions in expectations
      #
      #   Potential enhancements (without breaking changes):
      #     - Add more variables to ExpectationResult (memory usage, etc.)
      #     - Provide additional helper methods in evaluation context
      #     - Enhanced error reporting with better stack traces
      #
      # @param content [String] the expectation code to evaluate
      # @param expectation_result [ExpectationResult] container with actual_result and timing data
      # @return [Object] the result of evaluating the content
      def eval_expectation_content(content, expectation_result = nil)
        path  = @test_case.path
        range = @test_case.line_range

        if expectation_result
          # For performance expectations, timing data takes precedence for result/_
          if expectation_result.execution_time_ns
            timing_ms = expectation_result.execution_time_ms
            @context.define_singleton_method(:result) { timing_ms }
            @context.define_singleton_method(:_) { timing_ms }
          elsif expectation_result.actual_result
            # For regular expectations, use actual_result
            @context.define_singleton_method(:result) { expectation_result.actual_result }
            @context.define_singleton_method(:_) { expectation_result.actual_result }
          end
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
