# lib/tryouts/cli/formatters/base.rb

require_relative 'factory'
require_relative 'output_manager'

class Tryouts
  class CLI
    # Enhanced interface for all test output formatting
    module FormatterInterface

      attr_reader :current_indent

      # Phase-level output (major sections)
      def phase_header(message, file_count = nil, level = 0, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #phase_header"
      end

      # File-level operations
      def file_start(file_path, context_info = {}, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #file_start"
      end

      def file_end(file_path, context_info = {}, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #file_end"
      end

      def file_parsed(file_path, test_count, io = $stdout, setup_present: false, teardown_present: false)
        raise NotImplementedError, "#{self.class} must implement #file_parsed"
      end

      def file_execution_start(file_path, test_count, context_mode, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #file_execution_start"
      end

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #file_result"
      end

      # Test-level operations
      def test_start(test_case, index, total, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #test_start"
      end

      def test_end(test_case, index, total, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #test_end"
      end

      def test_result(test_case, result_status, actual_results = [], elapsed_time = nil, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #test_result"
      end

      def test_output(test_case, output_text, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #test_output"
      end

      # Setup/teardown operations
      def setup_start(line_range, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #setup_start"
      end

      def setup_output(output_text, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #setup_output"
      end

      def teardown_start(line_range, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #teardown_start"
      end

      def teardown_output(output_text, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #teardown_output"
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #batch_summary"
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #grand_total"
      end

      # Debug and diagnostic output
      def debug_info(message, level = 0, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #debug_info"
      end

      def trace_info(message, level = 0, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #trace_info"
      end

      def error_message(message, details = nil, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #error_message"
      end

      # Utility methods
      def raw_output(text, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #raw_output"
      end

      def separator(style = :light, io = $stdout)
        raise NotImplementedError, "#{self.class} must implement #separator"
      end

      def indent_text(text, level = nil)
        level ||= current_indent || 0
        indent  = '  ' * level
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
