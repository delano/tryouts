# lib/tryouts/expectation_evaluators/false.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class False < Base
      def self.handles?(expectation_type)
        expectation_type == :false # rubocop:disable Lint/BooleanSymbol
      end

      def evaluate(actual_result = nil)
        expression_result = eval_expectation_content(@expectation.content, actual_result)

        build_result(
          passed: expression_result == false,
          actual: expression_result,
          expected: 'false (boolean)',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
