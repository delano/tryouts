# lib/tryouts/expectation_evaluators/result_type.rb
#
# frozen_string_literal: true

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

      # The expression is evaluated in the test's binding, so constants resolve
      # exactly as they would in the test code, including classes the test
      # defined itself.
      def evaluate(actual_result = nil)
        expected_class = evaluate_expression
        unless expected_class.is_a?(Module)
          raise TypeError, "Expected a Class or Module, got #{expected_class.inspect}"
        end

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
