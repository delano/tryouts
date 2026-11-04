# lib/tryouts/expectation_evaluators/exception.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for exception expectations using syntax: #=!> expression
    #
    # PURPOSE:
    # - Declares that the test code is expected to raise
    # - Checks the raised exception by class or module, or by any expression
    #
    # SYNTAX: #=!> ErrorClass, or #=!> expression
    # Examples:
    #   Integer("abc")
    #   #=!> ArgumentError                         # Pass: error.is_a?(ArgumentError)
    #
    #   Integer("abc")
    #   #=!> StandardError                         # Pass: is_a? includes ancestors
    #
    #   Integer("abc")
    #   #=!> error.message.include?("abc")         # Pass: the expression is truthy
    #
    #   Integer("42")
    #   #=!> ArgumentError                         # Fail: nothing was raised
    #
    # MATCHING:
    # - If the expression evaluates to a Module (a class or a module such as
    #   Comparable), passes when error.is_a?(it)
    # - Otherwise passes when the expression is truthy
    # - Fails, and never re-runs the code, when the test raised nothing
    #
    # IMPLEMENTATION DETAILS:
    # - The test code runs exactly once, before any expectation. A test with
    #   a #=!> expectation may raise any exception except an interrupt,
    #   signal or exit (including a class that inherits from Exception
    #   directly); the exception is then context.error and also the result
    # - Expression is evaluated in the test's binding: it sees the test's
    #   locals, plus `error` (the exception), `result`/`_` (the same
    #   exception) and `elapsed_ms`
    # - Other expectations on the same test see the same `error`, and #=~>
    #   matches the exception message
    # - Expected display shows the class name or the expression value;
    #   actual display shows the raised class name or the message
    class Exception < Base
      def self.handles?(expectation_type)
        expectation_type == :exception
      end

      # The test code has already run, exactly once. If it raised, the exception
      # is context.error; if it did not, this expectation fails. It never runs
      # the test code again.
      def evaluate(actual_result = nil)
        caught_error = @context.error
        unless caught_error
          return build_result(
            passed: false,
            actual: "No exception was raised (result: #{actual_result.inspect})",
            expected: @expectation.content,
          )
        end

        expected_value = evaluate_expression
        if expected_value.is_a?(Module)
          build_result(
            passed: caught_error.is_a?(expected_value),
            actual: caught_error.class.name,
            expected: expected_value.name,
          )
        else
          build_result(
            passed: !!expected_value,
            actual: caught_error.message,
            expected: expected_value,
          )
        end
      rescue StandardError => ex
        build_result(
          passed: false,
          actual: caught_error.class.name,
          expected: EvaluationError.new(message: ex.message),
          error: ex,
        )
      end
    end
  end
end
