# lib/tryouts/expectation_evaluators/result_type.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class ResultType < Base
      def self.handles?(expectation_type)
        expectation_type == :result_type
      end

      def evaluate(actual_result = nil)
        expected_class = eval_expectation_content(@expectation.content, actual_result)

        build_result(
          passed: actual_result.is_a?(expected_class),
          actual: actual_result.class,
          expected: expected_class,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
