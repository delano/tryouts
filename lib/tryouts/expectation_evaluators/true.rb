# lib/tryouts/expectation_evaluators/true.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class True < Base
      def self.handles?(expectation_type)
        expectation_type == :true
      end

      def evaluate(actual_result = nil)
        expression_result = eval_expectation_content(@expectation.content, actual_result)

        build_result(
          passed: expression_result == true,
          actual: expression_result,
          expected: 'true (exactly)',
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
