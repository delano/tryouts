# lib/tryouts/expectation_evaluators/performance_time.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for performance time expectations using syntax: #=%> milliseconds
    #
    # PURPOSE:
    # - Validates that test execution time meets performance thresholds
    # - The expression after the arrow is a limit in milliseconds
    # - Provides performance regression testing for documentation-style tests
    #
    # SYNTAX: #=%> limit_ms
    # Examples:
    #   1 + 1           #=%> 100           # Pass: simple addition under 100ms
    #   sleep(0.01)     #=%> 15            # Pass: 10ms sleep under 15ms (+10% tolerance)
    #   Array.new(1000) #=%> 1             # Pass: array creation under 1ms
    #   sleep(0.001)    #=%> 0.1           # Fail: 1ms execution exceeds 0.1ms + 10%
    #
    #   @budget_ms = 50
    #   [3, 1, 2].sort
    #   #=%> @budget_ms                    # Pass: the limit can be any Numeric expression
    #   #=> [1, 2, 3]                      # result is still the sorted array
    #
    # VARIABLE AVAILABILITY:
    # - `result` / `_`: the test's value, as in every other expectation
    #   (not the timing)
    # - `elapsed_ms`: the measured run time in milliseconds (e.g. 5.23)
    # - The test's local and instance variables
    # The measurement is compared against the limit; to assert on it
    # directly, use another operator: `#==> elapsed_ms < 50`
    #
    # TOLERANCE LOGIC:
    # - Performance expectations use "less than or equal to + 10%" logic
    # - Formula: elapsed_ms <= limit_ms * 1.1
    # - This differs from strict window matching - only cares about upper bound
    # - Designed for performance regression testing, not precision timing
    #
    # IMPLEMENTATION DETAILS:
    # - Times the test code only, not setup, interludes or expectations
    # - Uses Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond),
    #   exposed as elapsed_ms rounded to two decimals by EvaluationContext
    # - A limit that is not Numeric fails the expectation with a TypeError
    # - Expected display shows evaluated limit (e.g., "100", "10.5")
    # - Actual display shows formatted timing (e.g., "5.23ms")
    #
    # DESIGN DECISIONS:
    # - Chosen "less than or equal to + 10%" over strict window for usability
    # - Nanosecond capture → millisecond display for precision + readability
    # - `result` keeps one meaning across all operators; the timing has its
    #   own name
    class PerformanceTime < Base
      def self.handles?(expectation_type)
        expectation_type == :performance_time
      end

      # The expression is a limit in milliseconds. `result` is still the test's
      # value; the measurement is `elapsed_ms`.
      def evaluate(actual_result = nil)
        actual_time_ms = @context.elapsed_ms
        if actual_time_ms.nil?
          return build_result(
            passed: false,
            actual: 'No timing data available',
            expected: 'Performance measurement',
            error: 'Performance expectations require execution timing data',
          )
        end

        expected_limit_ms = evaluate_expression
        unless expected_limit_ms.is_a?(Numeric)
          raise TypeError, "#=%> expects a number of milliseconds, got #{expected_limit_ms.class}"
        end

        # 10% tolerance absorbs scheduler jitter
        max_allowed_ms = expected_limit_ms * 1.1

        build_result(
          passed: actual_time_ms <= max_allowed_ms,
          actual: "#{actual_time_ms}ms",
          expected: expected_limit_ms,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
