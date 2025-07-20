# lib/tryouts/expectation_evaluators/result_type.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for result type expectations using syntax: #=:> ClassName
    #
    # PURPOSE:
    # - Validates that the test result is an instance of the expected class or its ancestors
    # - Supports both exact class matches and inheritance (String is_a? Object)
    # - Provides clean type validation for documentation-style tests
    #
    # SYNTAX: #=:> ClassName
    # Examples:
    #   "hello"     #=:> String     # Pass: String.is_a?(String)
    #   [1, 2, 3]   #=:> Array      # Pass: Array.is_a?(Array)
    #   42          #=:> Integer    # Pass: Integer.is_a?(Integer)
    #   "hello"     #=:> Object     # Pass: String.is_a?(Object) - inheritance
    #   "hello"     #=:> Integer    # Fail: String is not Integer
    #
    # IMPLEMENTATION DETAILS:
    # - Uses Ruby's is_a? method for type checking (supports inheritance)
    # - Evaluates expectation content to resolve class constants (String, Array, etc.)
    # - Expected display shows the evaluated class name (e.g., "String", "Integer")
    # - Actual display shows the actual result's class for easy comparison
    #
    # DESIGN DECISIONS:
    # - Chose is_a? over class == for inheritance support
    # - Class resolution through evaluation allows dynamic class references
    # - Clean expected/actual display focuses on type comparison
    class ResultType < Base
      def self.handles?(expectation_type)
        expectation_type == :result_type
      end

      def evaluate(actual_result = nil)
        result_packet = ResultPacket.from_result(actual_result)
        expected_class = eval_expectation_content(@expectation.content, result_packet)

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
