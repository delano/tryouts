# lib/tryouts/expectation_evaluators/regular.rb
#
# frozen_string_literal: true

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
    #   1 + 1         #=> 2                       # Pass: 2 == 2
    #   [1, 2, 3]     #=> [1, 2, 3]               # Pass: array equality
    #   "hello"       #=> "hello"                 # Pass: string equality
    #   [3, 1, 2]     #=> result.sort             # Fail: [3, 1, 2] != [1, 2, 3]
    #   [1, 2, 3]     #=> result.length           # Fail: [1, 2, 3] != 3
    #   { a: 1 }      #=> { a: 1 }                # Pass: hash equality
    #   [3, 1, 2].sort
    #   # => [1, 2, 3]                            # Pass: `# =>` is the same as `#=>`
    #
    # EQUALITY SEMANTICS:
    # - Uses Ruby's == operator for equality comparison
    # - Supports all Ruby types: primitives, collections, objects
    # - Type-sensitive: 2 != "2", [1] != 1, nil != false
    # - Reference-independent: compares values not object identity
    #
    # IMPLEMENTATION DETAILS:
    # - Expression is evaluated in the test's binding (see VARIABLE ACCESS)
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
    #
    # VARIABLE ACCESS:
    # - The test's local and instance variables, as the test code left them
    # - `result`: contains the actual test result value
    # - `_`: shorthand alias for the same actual result value
    # - `error`: the exception the test raised, or nil. A test that raises is
    #   a test error unless it also has a #=!>, #=:> or #=~> expectation
    # - `elapsed_ms`: run time of the test code
    # - Enables expectations like: #=> subtotal * 2, #=> @cart.size
    class Regular < Base
      def self.handles?(expectation_type)
        expectation_type == :regular
      end

      def evaluate(actual_result = nil)
        expected_value = evaluate_expression
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
