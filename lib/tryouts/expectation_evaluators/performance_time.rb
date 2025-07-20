# lib/tryouts/expectation_evaluators/performance_time.rb

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
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

        # Extract just the numeric value from expectation content (ignore comments)
        numeric_content = @expectation.content.split(/\s*#/).first.strip
        expected_time_ms = numeric_content.to_f
        expected_time_ns = expected_time_ms * 1_000_000 # Convert ms to ns
        tolerance_ns = expected_time_ns * 0.1 # 10% tolerance

        actual_time_ms = (execution_time_ns / 1_000_000.0).round(2)

        within_tolerance = (execution_time_ns - expected_time_ns).abs <= tolerance_ns

        build_result(
          passed: within_tolerance,
          actual: "#{actual_time_ms}ms",
          expected: "#{expected_time_ms}ms ±10%",
          expectation: numeric_content,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
