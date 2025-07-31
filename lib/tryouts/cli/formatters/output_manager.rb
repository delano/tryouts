# lib/tryouts/cli/formatters/output_manager.rb

class Tryouts
  class CLI
    # Output manager that coordinates all output through formatters
    class OutputManager
      attr_reader :formatter

      def initialize(formatter)
        @formatter = formatter
      end

      # Phase-level methods
      def processing_phase(file_count)
        @formatter.phase_header("PROCESSING #{file_count} FILES", file_count: file_count)
      end

      def execution_phase(test_count)
        @formatter.phase_header("EXECUTING #{test_count} TESTS", file_count: test_count)
      end

      def error_phase
        @formatter.phase_header('ERROR DETAILS')
      end

      # File-level methods
      def file_start(file_path, framework: :direct, context: :fresh)
        context_info = { framework: framework, context: context }
        @formatter.file_start(file_path, context_info: context_info)
      end

      def file_end(file_path, framework: :direct, context: :fresh)
        context_info = { framework: framework, context: context }
        @formatter.file_end(file_path, context_info: context_info)
      end

      def file_parsed(file_path, test_count, setup_present: false, teardown_present: false)
        @formatter.file_parsed(
          file_path,
          test_count: test_count,
          setup_present: setup_present,
          teardown_present: teardown_present
        )
      end

      def file_execution_start(file_path, test_count, context_mode)
        @formatter.file_execution_start(
          file_path,
          test_count: test_count,
          context_mode: context_mode
        )
      end

      def file_success(file_path, total_tests, failed_count, error_count, elapsed_time)
        @formatter.file_result(
          file_path,
          total_tests: total_tests,
          failed_count: failed_count,
          error_count: error_count,
          elapsed_time: elapsed_time
        )
      end

      def file_failure(file_path, error_message, backtrace = nil)
        @formatter.error_message(
          "#{Console.pretty_path(file_path)}: #{error_message}",
          backtrace: backtrace
        )
      end

      # Test-level methods
      def test_start(test_case, index, total)
        @formatter.test_start(test_case: test_case, index: index, total: total)
      end

      def test_end(test_case, index, total)
        @formatter.test_end(test_case: test_case, index: index, total: total)
      end

      def test_result(result_packet)
        @formatter.test_result(result_packet)
      end

      def test_output(test_case, output_text, result_packet)
        @formatter.test_output(
          test_case: test_case,
          output_text: output_text,
          result_packet: result_packet
        )
      end

      # Setup/teardown methods
      def setup_start(line_range)
        @formatter.setup_start(line_range: line_range)
      end

      def setup_output(output_text)
        @formatter.setup_output(output_text)
      end

      def teardown_start(line_range)
        @formatter.teardown_start(line_range: line_range)
      end

      def teardown_output(output_text)
        @formatter.teardown_output(output_text)
      end

      # Summary methods
      def batch_summary(failure_collector)
        @formatter.batch_summary(failure_collector)
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
        @formatter.grand_total(
          total_tests: total_tests,
          failed_count: failed_count,
          error_count: error_count,
          successful_files: successful_files,
          total_files: total_files,
          elapsed_time: elapsed_time
        )
      end

      # Debug methods
      def info(message, level = 0)
        @formatter.debug_info(message, level: level)
      end

      def trace(message, level = 0)
        @formatter.trace_info(message, level: level)
      end

      def error(message, backtrace = nil)
        @formatter.error_message(message, backtrace: backtrace)
      end
    end
  end
end
