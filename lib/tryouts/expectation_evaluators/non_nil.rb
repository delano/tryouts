# lib/tryouts/expectation_evaluators/non_nil.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for non-nil expectations using syntax: #=*>
    #
    # PURPOSE:
    # - Validates that the test result is not nil and no exception occurred
    # - Provides a simple "anything goes" expectation for existence checks
    # - Useful for API responses, object creation, method return values
    #
    # SYNTAX: #=*>
    # Examples:
    #   user = User.create(name: "test")
    #   #=*>                              # Pass: user object exists (not nil)
    #
    #   response = api_call()
    #   #=*>                              # Pass: got some response (not nil)
    #
    #   nil
    #   #=*>                              # Fail: result is nil
    #
    #   raise StandardError.new("error")
    #   #=*>                              # Fail: exception occurred
    #
    # VALIDATION LOGIC:
    # - Passes when result is not nil AND no exception was raised during execution
    # - Fails when result is nil OR an exception occurred
    # - Does not evaluate any additional expression (unlike other expectation types)
    #
    # IMPLEMENTATION DETAILS:
    # - Simple existence check without complex evaluation
    # - No expression parsing needed - syntax is just #=*>
    # - Expected display shows "non-nil result with no exception"
    # - Actual display shows the actual result value or exception
    #
    # DESIGN DECISIONS:
    # - Uses #=*> syntax where * represents "anything"
    # - Part of unified #= prefix convention for all expectation types
    # - Complements existing boolean and equality expectations
    # - Provides simple alternative to complex conditional expressions
    # - Useful for integration tests where exact values are unpredictable
    #
    # VARIABLE ACCESS:
    # - No special variables needed since no expression is evaluated
    # - Works purely on the actual test result value
    class NonNil < Base
      def self.handles?(expectation_type)
        expectation_type == :non_nil
      end

      def evaluate(actual_result = nil, caught_exception: nil)
        # Check if an exception occurred during test execution
        if caught_exception
          return build_result(
            passed: false,
            actual: "(#{caught_exception.class}) #{caught_exception.message}",
            expected: 'non-nil result with no exception',
          )
        end

        # Check if result is nil
        passed = !actual_result.nil?

        build_result(
          passed: passed,
          actual: actual_result,
          expected: 'non-nil result',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
