# lib/tryouts/expectation_evaluators/registry.rb

require_relative 'result_packet'
require_relative 'base'
require_relative 'regular'
require_relative 'exception'
require_relative 'boolean'
require_relative 'true'
require_relative 'false'
require_relative 'result_type'
require_relative 'regex_match'
require_relative 'performance_time'
require_relative 'intentional_failure'
require_relative 'output'

class Tryouts
  module ExpectationEvaluators
    class Registry
      @evaluators = []

      class << self
        attr_reader :evaluators

        def evaluator_for(expectation, test_case, context)
          evaluator_class = find_evaluator_class(expectation.type)

          unless evaluator_class
            raise ArgumentError, "No evaluator found for expectation type: #{expectation.type}"
          end

          evaluator_class.new(expectation, test_case, context)
        end

        def register(evaluator_class)
          unless evaluator_class < Base
            raise ArgumentError, 'Evaluator must inherit from ExpectationEvaluators::Base'
          end

          @evaluators << evaluator_class unless @evaluators.include?(evaluator_class)
        end

        def registered_evaluators
          @evaluators.dup
        end

        private

        def find_evaluator_class(expectation_type)
          @evaluators.find { |evaluator_class| evaluator_class.handles?(expectation_type) }
        end
      end

      # Auto-register built-in evaluators
      register(Regular)
      register(Exception)
      register(Boolean)
      register(True)
      register(False)
      register(ResultType)
      register(RegexMatch)
      register(PerformanceTime)
      register(IntentionalFailure)
      register(Output)
    end
  end
end
