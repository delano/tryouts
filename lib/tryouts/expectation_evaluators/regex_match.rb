# lib/tryouts/expectation_evaluators/regex_match.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for regex match expectations using syntax: #=~> /pattern/
    #
    # PURPOSE:
    # - Validates that the test result matches a regular expression pattern
    # - Supports all Ruby regex features (anchors, flags, groups, etc.)
    # - Provides pattern matching for string validation in documentation-style tests
    #
    # SYNTAX: #=~> /pattern/flags
    # Examples:
    #   "hello world"      #=~> /hello/           # Pass: basic pattern match
    #   "user@example.com" #=~> /^[^@]+@[^@]+$/   # Pass: email validation pattern
    #   "Phone: 555-1234"  #=~> /\d{3}-\d{4}/     # Pass: phone number pattern
    #   "HELLO WORLD"      #=~> /hello/i          # Pass: case insensitive match
    #   "hello world"      #=~> /goodbye/         # Fail: pattern not found
    #
    #   Integer("abc")
    #   #=~> /invalid value/                      # Pass: matches the exception message
    #
    # IMPLEMENTATION DETAILS:
    # - Converts actual_result to string using to_s for regex matching
    # - When the result is an exception (the test raised), matches its message
    # - A test with a #=~> expectation may raise a StandardError; the
    #   exception is then the result
    # - Uses String#match? (no match data, no $~ side effects)
    # - The expression is evaluated in the test's binding, so it may build the
    #   pattern from the test's locals
    # - Expected display shows pattern.inspect (e.g., "/hello/i", "/\d+/")
    # - Actual display shows stringified result for pattern comparison
    #
    # DESIGN DECISIONS:
    # - Always converts to string (allows regex matching on any object)
    # - Pattern evaluation supports dynamic regex construction
    # - Displays pattern.inspect for clear regex representation
    class RegexMatch < Base
      def self.handles?(expectation_type)
        expectation_type == :regex_match
      end

      def evaluate(actual_result = nil)
        pattern = evaluate_expression

        # A test that raised is matched on its message (`#=~> /not found/`)
        string_result = actual_result.is_a?(::Exception) ? actual_result.message : actual_result.to_s

        build_result(
          passed: string_result.match?(pattern),
          actual: string_result,
          expected: pattern.inspect,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
