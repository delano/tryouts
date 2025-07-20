# lib/tryouts/expectation_evaluators/performance_time.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for performance time expectations using syntax: #=%> milliseconds
    #
    # PURPOSE:
    # - Validates that test execution time meets performance thresholds
    # - Supports both static thresholds and dynamic expressions using timing data
    # - Provides performance regression testing for documentation-style tests
    #
    # SYNTAX: #=%> threshold_expression
    # Examples:
    #   1 + 1           #=%> 100           # Pass: simple addition under 100ms
    #   sleep(0.01)     #=%> 15            # Pass: 10ms sleep under 15ms (+10% tolerance)
    #   Array.new(1000) #=%> 1             # Pass: array creation under 1ms
    #   sleep(0.005)    #=%> result * 2    # Pass: 5ms execution, 10ms threshold
    #   sleep(0.001)    #=%> 0.1           # Fail: 1ms execution exceeds 0.1ms + 10%
    #
    # TIMING DATA AVAILABILITY:
    # In performance expectations, the timing data is available as:
    # - `result`: execution time in milliseconds (e.g., 5.23)
    # - `_`: alias for the same timing data
    # This allows expressions like: #=%> result * 2, #=%> _ + 10
    #
    # TOLERANCE LOGIC:
    # - Performance expectations use "less than or equal to + 10%" logic
    # - Formula: actual_time_ms <= expected_limit_ms * 1.1
    # - This differs from strict window matching - only cares about upper bound
    # - Designed for performance regression testing, not precision timing
    #
    # IMPLEMENTATION DETAILS:
    # - Timing captured in nanoseconds for precision, displayed in milliseconds
    # - Uses Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) for accuracy
    # - Expected display shows evaluated threshold (e.g., "100", "10.5")
    # - Actual display shows formatted timing (e.g., "5.23ms")
    # - Timing data passed via ResultPacket for extensibility
    #
    # DESIGN DECISIONS:
    # - Chosen "less than or equal to + 10%" over strict window for usability
    # - Nanosecond capture → millisecond display for precision + readability
    # - Expression evaluation with timing context for flexible thresholds
    # - Separate evaluate method signature to receive timing data from testbatch
    class PerformanceTime < Base
      def self.handles?(expectation_type)
        expectation_type == :performance_time
      end

      def evaluate(actual_result = nil, execution_time_ns = nil)
        if execution_time_ns.nil?
          return build_result(
            passed: false,
            actual: 'No timing data available',
            expected: 'Performance measurement',
            error: 'Performance expectations require execution timing data'
          )
        end

        # Create result packet with timing data available to expectation
        result_packet = ResultPacket.from_timing(actual_result, execution_time_ns)
        expected_limit_ms = eval_expectation_content(@expectation.content, result_packet)

        actual_time_ms = result_packet.execution_time_ms

        # Performance tolerance: actual <= expected + 10% (not strict window)
        max_allowed_ms = expected_limit_ms * 1.1
        within_tolerance = actual_time_ms <= max_allowed_ms

        build_result(
          passed: within_tolerance,
          actual: "#{actual_time_ms}ms",
          expected: expected_limit_ms,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
