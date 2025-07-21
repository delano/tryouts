# lib/tryouts/expectation_evaluators/regex_match.rb

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
    # IMPLEMENTATION DETAILS:
    # - Converts actual_result to string using to_s for regex matching
    # - Uses Ruby's =~ operator for pattern matching (returns match position or nil)
    # - Evaluates expectation content to resolve regex patterns with flags
    # - Expected display shows pattern.inspect (e.g., "/hello/i", "/\d+/")
    # - Actual display shows stringified result for pattern comparison
    #
    # DESIGN DECISIONS:
    # - Always converts to string (allows regex matching on any object)
    # - Uses =~ operator (Ruby standard) rather than match? for compatibility
    # - Pattern evaluation supports dynamic regex construction
    # - Displays pattern.inspect for clear regex representation
    class RegexMatch < Base
      def self.handles?(expectation_type)
        expectation_type == :regex_match
      end

      def evaluate(actual_result = nil)
        expectation_result = ExpectationResult.from_result(actual_result)
        pattern = eval_expectation_content(@expectation.content, expectation_result)

        # Convert actual_result to string for regex matching
        string_result = actual_result.to_s
        match_result = string_result =~ pattern

        build_result(
          passed: !match_result.nil?,
          actual: string_result,
          expected: pattern.inspect,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
