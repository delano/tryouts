# lib/tryouts/expectation_evaluators/regular.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for standard equality expectations using syntax: #=> expression
    #
    # PURPOSE:
    # - Validates that test result equals the evaluated expectation expression
    # - Provides the fundamental equality-based testing mechanism
    # - Serves as the default and most commonly used expectation type
    #
    # SYNTAX: #=> expression
    # Examples:
    #   1 + 1         #=> 2                        # Pass: 2 == 2
    #   [1, 2, 3]     #=> result.length            # Pass: [1,2,3] == 3 (fails, different types)
    #   [1, 2, 3]     #=> [1, 2, 3]               # Pass: array equality
    #   "hello"       #=> "hello"                 # Pass: string equality
    #   [1, 2, 3]     #=> result.sort              # Pass: [1,2,3] == [1,2,3]
    #   { a: 1 }      #=> { a: 1 }                # Pass: hash equality
    #   1 + 1         #=> result                  # Pass: 2 == 2 (result variable access)
    #
    # EQUALITY SEMANTICS:
    # - Uses Ruby's == operator for equality comparison
    # - Supports all Ruby types: primitives, collections, objects
    # - Type-sensitive: 2 != "2", [1] != 1, nil != false
    # - Reference-independent: compares values not object identity
    #
    # IMPLEMENTATION DETAILS:
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows the evaluated expression result (not raw content)
    # - Actual display shows the test result value
    # - Most flexible evaluator supporting arbitrary Ruby expressions
    #
    # DESIGN DECISIONS:
    # - Standard equality provides intuitive testing behavior
    # - Expression evaluation enables dynamic expectations (result.length, etc.)
    # - Uses #=> syntax as the canonical expectation notation
    # - Evaluated expected display prevents confusion with literal text content
    # - Part of unified #= prefix convention for all expectation types
    # - Serves as fallback when no specialized evaluator applies
    #
    # VARIABLE ACCESS:
    # - `result`: contains the actual test result value
    # - `_`: shorthand alias for the same actual result value
    # - Enables expectations like: #=> result.upcase, #=> _.first, #=> result * 2
    class Regular < Base
      def self.handles?(expectation_type)
        expectation_type == :regular
      end

      def evaluate(actual_result = nil)
        expectation_result = ExpectationResult.from_result(actual_result)
        expected_value = eval_expectation_content(@expectation.content, expectation_result)

        build_result(
          passed: actual_result == expected_value,
          actual: actual_result,
          expected: expected_value,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
