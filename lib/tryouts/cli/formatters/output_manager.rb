# lib/tryouts/cli/formatters/output_manager.rb

class Tryouts
  class CLI

    # Output manager that coordinates all output through formatters
    class OutputManager
      attr_reader :formatter

      def initialize(formatter)
        @formatter    = formatter
        @indent_level = 0
      end

      # Phase-level methods
      def processing_phase(file_count, level = 0)
        @formatter.phase_header("PROCESSING #{file_count} FILES", file_count, level)
      end

      def execution_phase(test_count, level = 1)
        @formatter.phase_header("EXECUTING #{test_count} TESTS", test_count, level)
      end

      def error_phase(level = 1)
        @formatter.phase_header('ERROR DETAILS', level)
      end

      # File-level methods
      def file_start(file_path, framework: :direct, context: :fresh)
        context_info = { framework: framework, context: context }
        @formatter.file_start(file_path, context_info)
      end

      def file_parsed(file_path, test_count, setup_present: false, teardown_present: false)
        with_indent(1) do
          @formatter.file_parsed(file_path, test_count,
            setup_present: setup_present,
            teardown_present: teardown_present
          )
        end
      end

      def file_execution_start(file_path, test_count, context_mode)
        @formatter.file_execution_start(file_path, test_count, context_mode)
      end

      def file_success(file_path, total_tests, failed_count, error_count, elapsed_time)
        with_indent(1) do
          @formatter.file_result(file_path, total_tests, failed_count, error_count, elapsed_time)
        end
      end

      def file_failure(file_path, error_message, backtrace = nil)
        with_indent(1) do
          @formatter.error_message("#{Console.pretty_path(file_path)}: #{error_message}", backtrace)
        end
      end

      # Test-level methods
      def test_start(test_case, index, total)
        with_indent(2) do
          @formatter.test_start(test_case, index, total)
        end
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil)
        @formatter.test_result(test_case, result_status, actual_results, elapsed_time)
      end

      def test_output(test_case, output_text)
        @formatter.test_output(test_case, output_text)
      end

      # Setup/teardown methods
      def setup_start(line_range)
        with_indent(2) do
          @formatter.setup_start(line_range)
        end
      end

      def setup_output(output_text)
        @formatter.setup_output(output_text)
      end

      def teardown_start(line_range)
        with_indent(2) do
          @formatter.teardown_start(line_range)
        end
      end

      def teardown_output(output_text)
        @formatter.teardown_output(output_text)
      end

      # Summary methods
      def batch_summary(total_tests, failed_count, elapsed_time)
        @formatter.batch_summary(total_tests, failed_count, elapsed_time)
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
        @formatter.grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
      end

      # Debug methods
      def info(message, level = 0)
        with_indent(level) do
          @formatter.debug_info(message, level)
        end
      end

      def trace(message, level = 0)
        with_indent(level) do
          @formatter.trace_info(message, level)
        end
      end

      def error(message, backtrace = nil)
        @formatter.error_message(message, backtrace)
      end

      # Utility methods
      def raw(text)
        @formatter.raw_output(text)
      end

      def separator(style = :light)
        @formatter.separator(style)
      end

      private

      def with_indent(level)
        old_level     = @indent_level
        @indent_level = level
        yield
      ensure
        @indent_level = old_level
      end
    end

  end
end
