# lib/tryouts/expectation_evaluators/exception.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Exception < Base
      def self.handles?(expectation_type)
        expectation_type == :exception
      end

      # The test code has already run, exactly once. If it raised, the exception
      # is context.error; if it did not, this expectation fails. It never runs
      # the test code again.
      def evaluate(actual_result = nil)
        caught_error = @context.error
        unless caught_error
          return build_result(
            passed: false,
            actual: "No exception was raised (result: #{actual_result.inspect})",
            expected: @expectation.content,
          )
        end

        expected_value = evaluate_expression
        if expected_value.is_a?(Module)
          build_result(
            passed: caught_error.is_a?(expected_value),
            actual: caught_error.class.name,
            expected: expected_value.name,
          )
        else
          build_result(
            passed: !!expected_value,
            actual: caught_error.message,
            expected: expected_value,
          )
        end
      rescue StandardError => ex
        build_result(
          passed: false,
          actual: caught_error.class.name,
          expected: "EXPECTED: #{ex.message}",
          error: ex,
        )
      end
    end
  end
end
