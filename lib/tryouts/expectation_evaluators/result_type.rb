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
    #   "hello"     #=:> String       # Pass: "hello".is_a?(String)
    #   [1, 2, 3]   #=:> Array        # Pass: [1, 2, 3].is_a?(Array)
    #   42          #=:> Integer      # Pass: 42.is_a?(Integer)
    #   "hello"     #=:> Object       # Pass: inheritance
    #   42          #=:> Comparable   # Pass: modules work too
    #   "hello"     #=:> Integer      # Fail: "hello" is not an Integer
    #
    #   Point = Struct.new(:x, :y)
    #   Point.new(1, 2)
    #   #=:> Point                    # Pass: constants the test defined resolve
    #
    #   Integer("abc")
    #   #=:> ArgumentError            # Pass: the test raised, result is the exception
    #
    # IMPLEMENTATION DETAILS:
    # - Uses Ruby's is_a? method for type checking (supports inheritance)
    # - The expression is evaluated in the test's binding, so constants resolve
    #   exactly as they do in the test code; there is no Object.const_get
    #   fallback. An unknown constant is a NameError and the expectation fails
    # - The expression must evaluate to a Class or Module, otherwise the
    #   expectation fails with a TypeError
    # - A test with a #=:> expectation may raise a StandardError; the
    #   exception is then the result, so its class can be checked
    # - Expected display shows the evaluated class; actual display shows the
    #   result's class
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
