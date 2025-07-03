# lib/tryouts/cli/formatters/base.rb

require_relative 'factory'
require_relative 'output_manager'

class Tryouts
  class CLI
    # Enhanced interface for all test output formatting
    module FormatterInterface
      # Phase-level output (major sections)
      def phase_header(message, file_count = nil, level = 0)
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

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time)
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

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time)
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

      def indent_text(text, level)
        indent = '  ' * level
        "#{indent}#{text}"
      end

      def with_indent(level)
        old_indent      = @current_indent
        @current_indent = level
        yield
      ensure
        @current_indent = old_indent
      end
    end

  end
end
