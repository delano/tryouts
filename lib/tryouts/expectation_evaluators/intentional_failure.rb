# lib/tryouts/expectation_evaluators/intentional_failure.rb

require_relative 'base'
require_relative 'regular'
require_relative '../test_case'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for intentional failure expectations using syntax: #=<> expression
    #
    # PURPOSE:
    # - Validates that an expectation intentionally fails (passes when the underlying expectation fails)
    # - Provides ability to test negative cases and expected failures
    # - Useful for testing error conditions and boundary cases
    #
    # SYNTAX: #=<> expression
    # Examples:
    #   1 + 1          #=<> 3                    # Pass: 1+1 ≠ 3, so failure expected
    #   "hello"        #=<> result.include?("x") # Pass: "hello" doesn't contain "x"
    #   [1, 2, 3]      #=<> result.empty?        # Pass: array is not empty
    #   "test"         #=<> /\d+/                # Pass: "test" doesn't match digits
    #
    # FAILURE INVERSION:
    # - Takes any valid expectation expression and inverts the result
    # - If underlying expectation would pass, intentional failure fails
    # - If underlying expectation would fail, intentional failure passes
    # - Preserves all error details and content from underlying expectation
    #
    # IMPLEMENTATION DETAILS:
    # - Uses delegation pattern to wrap the regular evaluator
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows the evaluated expression result for clarity
    # - Actual display shows the test result value
    # - Inverts only the final passed/failed status, preserving other metadata
    #
    # DESIGN DECISIONS:
    # - Uses #=<> syntax (angle brackets suggest "opposite/inverted direction")
    # - Delegates to regular evaluator to maintain consistency
    # - Preserves original expectation details for debugging
    # - Clear messaging indicates this is an intentional failure test
    # - Part of unified #= prefix convention for all expectation types
    #
    # DELEGATION PATTERN:
    # - Creates a temporary regular expectation with same content
    # - Delegates evaluation to Regular evaluator
    # - Inverts the passed result while preserving actual/expected values
    # - Provides clear messaging about intentional failure semantics
    class IntentionalFailure < Base
      def self.handles?(expectation_type)
        expectation_type == :intentional_failure
      end

      def evaluate(actual_result = nil)
        # Create a temporary regular expectation for delegation
        regular_expectation = Expectation.new(content: @expectation.content, type: :regular)

        # Delegate to regular evaluator
        regular_evaluator = Regular.new(regular_expectation, @test_case, @context)
        regular_result = regular_evaluator.evaluate(actual_result)

        # Invert the result while preserving metadata
        build_result(
          passed: !regular_result[:passed],
          actual: regular_result[:actual],
          expected: "NOT #{regular_result[:expected]} (intentional failure)",
          expectation: @expectation.content
        )
      rescue StandardError => ex
        # If evaluation itself fails (not the expectation), that's a real error
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
