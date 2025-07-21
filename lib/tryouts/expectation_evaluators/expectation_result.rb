# lib/tryouts/expectation_evaluators/expectation_result.rb

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
    #   ExpectationResult.from_result(actual_result)                           # Regular expectations
    #   ExpectationResult.from_timing(actual_result, execution_time_ns)        # Performance expectations
    #   ExpectationResult.from_execution_with_output(actual_result, stdout, stderr) # Output expectations
    #
    # Variables available in eval_expectation_content:
    #   result, _ : actual_result (regular) or execution_time_ms (performance)
    ExpectationResult = Data.define(:actual_result, :execution_time_ns, :start_time_ns, :end_time_ns, :stdout_content, :stderr_content) do
      # Convert nanoseconds to milliseconds for human-readable timing
      # Used for display and as the value of `result`/`_` variables in performance expectations
      def execution_time_ms
        execution_time_ns ? (execution_time_ns / 1_000_000.0).round(2) : nil
      end

      # Helper to create a basic packet with just actual result
      # Used by: regular, true, false, boolean, result_type, regex_match, exception evaluators
      def self.from_result(actual_result)
        new(
          actual_result: actual_result,
          execution_time_ns: nil,
          start_time_ns: nil,
          end_time_ns: nil,
          stdout_content: nil,
          stderr_content: nil
        )
      end

      # Helper to create a timing packet with execution data
      # Used by: performance_time evaluator
      # Future: Could accept additional timing or resource metrics
      def self.from_timing(actual_result, execution_time_ns, start_time_ns = nil, end_time_ns = nil)
        new(
          actual_result: actual_result,
          execution_time_ns: execution_time_ns,
          start_time_ns: start_time_ns,
          end_time_ns: end_time_ns,
          stdout_content: nil,
          stderr_content: nil
        )
      end

      # Helper to create a packet with captured output data
      # Used by: output evaluator for stdout/stderr expectations
      def self.from_execution_with_output(actual_result, stdout_content, stderr_content, execution_time_ns = nil)
        new(
          actual_result: actual_result,
          execution_time_ns: execution_time_ns,
          start_time_ns: nil,
          end_time_ns: nil,
          stdout_content: stdout_content,
          stderr_content: stderr_content
        )
      end
    end
  end
end
