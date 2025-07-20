# lib/tryouts/expectation_evaluators/regular.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Regular < Base
      def self.handles?(expectation_type)
        expectation_type == :regular
      end

      def evaluate(actual_result = nil)
        expected_value = eval_expectation_content(@expectation.content, actual_result)

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
