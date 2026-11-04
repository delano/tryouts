# lib/tryouts/expectation_evaluators/intentional_failure.rb
#
# frozen_string_literal: true

require_relative 'base'
require_relative 'regular'
require_relative '../test_case'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for negated expectations using syntax: #=<> expression
    #
    # PURPOSE:
    # - Asserts what the result must NOT be
    # - Provides ability to test negative cases and boundary conditions
    # - Historically called "intentional failure"; it is a negation, and a
    #   passing #=<> is a passing test
    #
    # SYNTAX: #=<> expression
    # Examples:
    #   "order-42"     #=<> /\A\d+\z/            # Pass: does not match the Regexp
    #   [1, 2, 3]      #=<> result.empty?        # Pass: the predicate is false
    #   "hello"        #=<> result.include?("x") # Pass: the predicate is false
    #   1 + 1          #=<> 3                    # Pass: 2 != 3
    #   1 + 1          #=<> 2                    # Fail: 2 == 2
    #   "test-1"       #=<> /\d/                 # Fail: matches the Regexp
    #
    # THE THREE NEGATION FORMS (chosen by the evaluated expression):
    # - Regexp: the result, converted with to_s, must not match it
    # - true or false, when the result itself is not a boolean: the
    #   expression is a predicate about the result and must be false
    # - Anything else (including true/false against a boolean result):
    #   result != expression
    #
    # IMPLEMENTATION DETAILS:
    # - Self-contained; it does not delegate to the Regular evaluator
    # - Expression is evaluated in the test's binding: it sees the test's
    #   locals, plus `result`/`_` (the test value), `error` and `elapsed_ms`
    # - Expected display reads "NOT ..." followed by the negated condition
    # - Actual display shows the test result value
    #
    # DESIGN DECISIONS:
    # - Uses #=<> syntax (angle brackets suggest "opposite/inverted direction")
    # - One operator covers "must not match", "must not hold" and "must not
    #   equal", so negative cases read like their positive counterparts
    # - Part of unified #= prefix convention for all expectation types
    class IntentionalFailure < Base
      def self.handles?(expectation_type)
        expectation_type == :intentional_failure
      end

      # Negates whatever the expression says, so the expectation holds when:
      # - the expression is a Regexp and the result does not match it
      # - the expression is true/false (a predicate about a non-boolean result)
      #   and it is false
      # - otherwise, the result is not == to the expression
      def evaluate(actual_result = nil)
        expected_value      = evaluate_expression
        passed, description = negate(actual_result, expected_value)

        build_result(
          passed: passed,
          actual: actual_result,
          expected: "NOT #{description}",
          expectation: @expectation.content,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end

      private

      def negate(actual_result, expected_value)
        boolean = [true, false]
        if expected_value.is_a?(Regexp)
          [actual_result.to_s !~ expected_value, "matching #{expected_value.inspect}"]
        elsif boolean.include?(expected_value) && !boolean.include?(actual_result)
          [expected_value == false, "#{@expectation.content} (is #{expected_value})"]
        else
          [actual_result != expected_value, expected_value.inspect]
        end
      end
    end
  end
end
