# lib/tryouts/expectation_evaluators/true.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for boolean true expectations using syntax: #==> expression
    #
    # PURPOSE:
    # - Validates that an expression evaluates to exactly true (not truthy)
    # - Provides explicit boolean validation for documentation-style tests
    # - Distinguishes between true/false and truthy/falsy values
    #
    # SYNTAX: #==> boolean_expression
    # Examples:
    #   [1, 2, 3]  #==> result.length == 3        # Pass: expression is true
    #   [1, 2, 3]  #==> result.include?(2)        # Pass: expression is true
    #   []         #==> result.empty?             # Pass: expression is true
    #   [1, 2, 3]  #==> result.empty?             # Fail: expression is false
    #   [1, 2, 3]  #==> result.length             # Fail: expression is 3 (truthy but not true)
    #
    # BOOLEAN STRICTNESS:
    # - Only passes when expression evaluates to exactly true (not truthy)
    # - Fails for false, nil, 0, "", [], {}, or any non-true value
    # - Uses Ruby's === comparison for exact boolean matching
    # - Encourages explicit boolean expressions in documentation
    #
    # IMPLEMENTATION DETAILS:
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows 'true (exactly)' for clarity
    # - Actual display shows the evaluated expression result
    # - Distinguishes from regular expectations through strict true matching
    #
    # DESIGN DECISIONS:
    # - Strict true matching prevents accidental truthy value acceptance
    # - Clear expected display explains the exact requirement
    # - Expression evaluation provides flexible boolean logic testing
    # - Part of unified #= prefix convention for all expectation types
    class True < Base
      def self.handles?(expectation_type)
        expectation_type == :true # rubocop:disable Lint/BooleanSymbol
      end

      def evaluate(actual_result = nil)
        result_packet     = ResultPacket.from_result(actual_result)
        expression_result = eval_expectation_content(@expectation.content, result_packet)

        build_result(
          passed: expression_result == true,
          actual: expression_result,
          expected: true,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
