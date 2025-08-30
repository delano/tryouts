# lib/tryouts/cli/formatters/base.rb

require_relative 'output_manager'

class Tryouts
  class CLI
    # Enhanced interface for all test output formatting
    module FormatterInterface
      attr_reader :stdout, :stderr, :current_indent

      def initialize(options = {})
        @stdout = options.fetch(:stdout, $stdout)
        @stderr = options.fetch(:stderr, $stderr)
        @current_indent = 0
        @options = options
      end

      # Phase-level output (major sections)
      def phase_header(message, file_count: nil)
        # Default: no output
      end

      # File-level operations
      def file_start(file_path, context_info: {})
        # Default: no output
      end

      def file_end(file_path, context_info: {})
        # Default: no output
      end

      def file_parsed(file_path, test_count:, setup_present: false, teardown_present: false)
        # Default: no output
      end

      def parser_warnings(file_path, warnings:)
        # Default: no output - override in specific formatters
      end

      def file_execution_start(file_path, test_count:, context_mode:)
        # Default: no output
      end

      def file_result(file_path, total_tests:, failed_count:, error_count:, elapsed_time: nil)
        # Default: no output
      end

      # Test-level operations
      def test_start(test_case:, index:, total:)
        # Default: no output
      end

      def test_end(test_case:, index:, total:)
        # Default: no output
      end

      def test_result(result_packet)
        # Default: no output
      end

      def test_output(test_case:, output_text:, result_packet:)
        # Default: no output
      end

      # Setup/teardown operations
      def setup_start(line_range:)
        # Default: no output
      end

      def setup_output(output_text)
        # Default: no output
      end

      def teardown_start(line_range:)
        # Default: no output
      end

      def teardown_output(output_text)
        # Default: no output
      end

      # Summary operations
      def batch_summary(failure_collector)
        # Default: no output
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:)
        # Default: no output
      end

      # Debug and diagnostic output
      def debug_info(message, level: 0)
        # Default: no output
      end

      def trace_info(message, level: 0)
        # Default: no output
      end

      def error_message(message, backtrace: nil)
        # Default: no output
      end

      # Live status capability negotiation
      def live_status_capabilities
        {
          supports_coordination: false,    # Can work with coordinated output
          output_frequency: :medium,       # :low, :medium, :high
          requires_tty: false,             # Must have TTY to function
        }
      end

      # Live status integration (optional methods)
      def set_live_status_manager(manager)
        @live_status_manager = manager
      end

      def live_status_manager
        @live_status_manager
      end

      # Standard output methods that coordinate with live status automatically
      def write(text)
        if @live_status_manager&.enabled?
          @live_status_manager.write_string(text)
        else
          @stdout.print(text)
        end
      end

      def puts(text = '')
        write("#{text}\n")
      end

      # Optional: formatters can implement this to provide custom live status updates
      def update_live_status(state_updates = {})
        @live_status_manager&.update_status(state_updates)
      end

      protected

      # Utility methods for formatters to use
      def indent_text(text, level = nil)
        level ||= current_indent || 0
        indent = '  ' * level
        "#{indent}#{text}"
      end

      def with_indent(level)
        old_indent = @current_indent
        @current_indent = level
        yield
      ensure
        @current_indent = old_indent
      end

      def separator(style = :light)
        width = @options.fetch(:line_width, 60)
        case style
        when :heavy
          '=' * width
        when :light
          '-' * width
        when :dotted
          '.' * width
        else
          '-' * width
        end
      end

      def format_timing(elapsed_time)
        return '' unless elapsed_time

        if elapsed_time < 0.001
          " (#{(elapsed_time * 1_000_000).round}μs)"
        elsif elapsed_time < 1
          " (#{(elapsed_time * 1000).round}ms)"
        else
          " (#{elapsed_time.round(2)}s)"
        end
      end
    end
  end
end
