# lib/tryouts/expectation_evaluators/boolean.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Boolean < Base
      def self.handles?(expectation_type)
        expectation_type == :boolean
      end

      def evaluate(actual_result = nil)
        expression_result = eval_expectation_content(@expectation.content, actual_result)

        build_result(
          passed: [true, false].include?(expression_result),
          actual: expression_result,
          expected: 'true or false (boolean)',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
