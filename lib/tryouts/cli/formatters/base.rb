# lib/tryouts/cli/formatters/base.rb

class Tryouts
  class CLI
    # Enhanced interface for all test output formatting
    module FormatterInterface
      # Phase-level output (major sections)
      def phase_header(message, file_count = nil)
        raise NotImplementedError, "#{self.class} must implement #phase_header"
      end

      # File-level operations
      def file_start(file_path, context_info = {})
        raise NotImplementedError, "#{self.class} must implement #file_start"
      end

      def file_parsed(file_path, test_count, setup_present: false, teardown_present: false)
        raise NotImplementedError, "#{self.class} must implement #file_parsed"
      end

      def file_execution_start(file_path, test_count, context_mode)
        raise NotImplementedError, "#{self.class} must implement #file_execution_start"
      end

      def file_result(file_path, total_tests, failed_count, elapsed_time)
        raise NotImplementedError, "#{self.class} must implement #file_result"
      end

      # Test-level operations
      def test_start(test_case, index, total)
        raise NotImplementedError, "#{self.class} must implement #test_start"
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil)
        raise NotImplementedError, "#{self.class} must implement #test_result"
      end

      # Setup/teardown operations
      def setup_start(line_range)
        raise NotImplementedError, "#{self.class} must implement #setup_start"
      end

      def setup_output(output_text)
        raise NotImplementedError, "#{self.class} must implement #setup_output"
      end

      def teardown_start(line_range)
        raise NotImplementedError, "#{self.class} must implement #teardown_start"
      end

      def teardown_output(output_text)
        raise NotImplementedError, "#{self.class} must implement #teardown_output"
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time)
        raise NotImplementedError, "#{self.class} must implement #batch_summary"
      end

      def grand_total(total_tests, failed_count, successful_files, total_files, elapsed_time)
        raise NotImplementedError, "#{self.class} must implement #grand_total"
      end

      # Debug and diagnostic output
      def debug_info(message, level = 0)
        raise NotImplementedError, "#{self.class} must implement #debug_info"
      end

      def trace_info(message, level = 0)
        raise NotImplementedError, "#{self.class} must implement #trace_info"
      end

      def error_message(message, details = nil)
        raise NotImplementedError, "#{self.class} must implement #error_message"
      end

      # Utility methods
      def raw_output(text)
        raise NotImplementedError, "#{self.class} must implement #raw_output"
      end

      def separator(style = :light)
        raise NotImplementedError, "#{self.class} must implement #separator"
      end
    end

    # Output manager that coordinates all output through formatters
    class OutputManager
      attr_reader :formatter

      def initialize(formatter)
        @formatter    = formatter
        @indent_level = 0
      end

      # Phase-level methods
      def processing_phase(file_count)
        @formatter.phase_header("PROCESSING #{file_count} FILES", file_count)
      end

      def execution_phase(test_count)
        @formatter.phase_header("EXECUTING #{test_count} TESTS", test_count)
      end

      def error_phase
        @formatter.phase_header('ERROR DETAILS')
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

      def file_success(file_path, total_tests, failed_count, elapsed_time)
        with_indent(1) do
          @formatter.file_result(file_path, total_tests, failed_count, elapsed_time)
        end
      end

      def file_failure(file_path, error_message, error_details = nil)
        with_indent(1) do
          @formatter.error_message("#{Console.pretty_path(file_path)}: #{error_message}", error_details)
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

      def grand_total(total_tests, failed_count, successful_files, total_files, elapsed_time)
        @formatter.grand_total(total_tests, failed_count, successful_files, total_files, elapsed_time)
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

      def error(message, details = nil)
        @formatter.error_message(message, details)
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

    # Factory for creating formatters and output managers
    class FormatterFactory
      def self.create_output_manager(options = {})
        formatter = create_formatter(options)
        OutputManager.new(formatter)
      end

      def self.create_formatter(options = {})
        case options
        in { verbose: true, fails_only: true }
          VerboseFailsFormatter.new(options)
        in { verbose: true }
          VerboseFormatter.new(options)
        in { quiet: true }
          QuietFormatter.new(options)
        in { compact: true } | {} | _
          CompactFormatter.new(options)
        end
      end
    end
  end
end
