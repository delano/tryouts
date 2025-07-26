# lib/tryouts/expectation_evaluators/boolean.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for flexible boolean expectations using syntax: #=|> expression
    #
    # PURPOSE:
    # - Validates that an expression evaluates to either true or false (not truthy/falsy)
    # - Provides lenient boolean validation accepting both true and false values
    # - Distinguishes from strict true/false evaluators that require specific values
    #
    # SYNTAX: #=|> boolean_expression
    # Examples:
    #   [1, 2, 3]  #=|> result.empty?             # Pass: expression is false
    #   []         #=|> result.empty?             # Pass: expression is true
    #   [1, 2, 3]  #=|> result.include?(2)        # Pass: expression is true
    #   [1, 2, 3]  #=|> result.include?(5)        # Pass: expression is false
    #   [1, 2, 3]  #=|> result.length             # Fail: expression is 3 (truthy but not boolean)
    #   []         #=|> result.first              # Fail: expression is nil (falsy but not boolean)
    #
    # BOOLEAN STRICTNESS:
    # - Only passes when expression evaluates to exactly true OR exactly false
    # - Fails for nil, 0, "", [], {}, or any non-boolean value
    # - Uses Ruby's Array#include? for boolean type checking
    # - More lenient than True/False evaluators but stricter than truthy/falsy
    #
    # IMPLEMENTATION DETAILS:
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows 'true or false' indicating flexible acceptance
    # - Actual display shows the evaluated expression result
    # - Distinguishes from regular expectations through boolean type validation
    #
    # DESIGN DECISIONS:
    # - Flexible boolean matching allows either true or false values
    # - Clear expected display explains the dual acceptance requirement
    # - Expression evaluation provides boolean logic testing with flexibility
    # - Part of unified #= prefix convention for all expectation types
    # - Uses #=|> syntax to visually represent OR logic (true OR false)
    class Boolean < Base
      def self.handles?(expectation_type)
        expectation_type == :boolean
      end

      def evaluate(actual_result = nil)
        expectation_result = ExpectationResult.from_result(actual_result)
        expression_result  = eval_expectation_content(@expectation.content, expectation_result)

        build_result(
          passed: [true, false].include?(expression_result),
          actual: expression_result,
          expected: 'true or false',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
