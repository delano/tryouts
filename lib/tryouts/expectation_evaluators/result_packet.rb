# lib/tryouts/expectation_evaluators/result_packet.rb

class Tryouts
  module ExpectationEvaluators
    # Extensible container for evaluation context data
    #
    # Provides immutable data structure for passing test results and timing data to evaluators.
    # Uses Data.define for lightweight implementation. Stores timing in nanoseconds internally,
    # converts to milliseconds for display. Enables adding future metrics (memory, CPU) without
    # breaking evaluator method signatures.
    #
    # Usage:
    #   ResultPacket.from_result(actual_result)                    # Regular expectations
    #   ResultPacket.from_timing(actual_result, execution_time_ns) # Performance expectations
    #
    # Variables available in eval_expectation_content:
    #   result, _ : actual_result (regular) or execution_time_ms (performance)
    ResultPacket = Data.define(:actual_result, :execution_time_ns, :start_time_ns, :end_time_ns) do
      # Convert nanoseconds to milliseconds for human-readable timing
      # Used for display and as the value of `result`/`_` variables in performance expectations
      def execution_time_ms
        execution_time_ns ? (execution_time_ns / 1_000_000.0).round(2) : nil
      end

      # Helper to create a basic packet with just actual result
      # Used by: regular, true, false, boolean, result_type, regex_match, exception evaluators
      def self.from_result(actual_result)
        new(actual_result: actual_result, execution_time_ns: nil, start_time_ns: nil, end_time_ns: nil)
      end

      # Helper to create a timing packet with execution data
      # Used by: performance_time evaluator
      # Future: Could accept additional timing or resource metrics
      def self.from_timing(actual_result, execution_time_ns, start_time_ns = nil, end_time_ns = nil)
        new(
          actual_result: actual_result,
          execution_time_ns: execution_time_ns,
          start_time_ns: start_time_ns,
          end_time_ns: end_time_ns
        )
      end
    end
  end
end
