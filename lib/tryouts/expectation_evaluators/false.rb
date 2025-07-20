# lib/tryouts/expectation_evaluators/false.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for boolean false expectations using syntax: #=/=> expression
    #
    # PURPOSE:
    # - Validates that an expression evaluates to exactly false (not falsy)
    # - Provides explicit boolean validation for documentation-style tests
    # - Distinguishes between true/false and truthy/falsy values
    #
    # SYNTAX: #=/=> boolean_expression
    # Examples:
    #   [1, 2, 3]  #=/=> result.empty?            # Pass: expression is false
    #   [1, 2, 3]  #=/=> result.include?(5)       # Pass: expression is false
    #   []         #=/=> result.include?(1)       # Pass: expression is false
    #   []         #=/=> result.empty?            # Fail: expression is true
    #   [1, 2, 3]  #=/=> result.first             # Fail: expression is 1 (truthy but not false)
    #   []         #=/=> result.first             # Fail: expression is nil (falsy but not false)
    #
    # BOOLEAN STRICTNESS:
    # - Only passes when expression evaluates to exactly false (not falsy)
    # - Fails for true, nil, 0, "", [], {}, or any non-false value
    # - Uses Ruby's === comparison for exact boolean matching
    # - Encourages explicit boolean expressions in documentation
    #
    # IMPLEMENTATION DETAILS:
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows 'false (exactly)' for clarity
    # - Actual display shows the evaluated expression result
    # - Distinguishes from regular expectations through strict false matching
    #
    # DESIGN DECISIONS:
    # - Strict false matching prevents accidental falsy value acceptance
    # - Clear expected display explains the exact requirement
    # - Expression evaluation provides flexible boolean logic testing
    # - Part of unified #= prefix convention for all expectation types
    # - Uses #=/=> syntax to visually distinguish from true expectations
    class False < Base
      def self.handles?(expectation_type)
        expectation_type == :false # rubocop:disable Lint/BooleanSymbol
      end

      def evaluate(actual_result = nil)
        result_packet = ResultPacket.from_result(actual_result)
        expression_result = eval_expectation_content(@expectation.content, result_packet)

        build_result(
          passed: expression_result == false,
          actual: expression_result,
          expected: 'false (exactly)',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
