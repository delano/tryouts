# lib/tryouts/expectation_evaluators/regex_match.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class RegexMatch < Base
      def self.handles?(expectation_type)
        expectation_type == :regex_match
      end

      def evaluate(actual_result = nil)
        pattern = eval_expectation_content(@expectation.content, actual_result)

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
