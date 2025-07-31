# lib/tryouts/cli/formatters/live_status_formatter.rb

require_relative 'test_run_state'
require_relative 'tty_status_display'

class Tryouts
  class CLI
    # Decorator that adds live status display to any formatter
    class LiveStatusFormatter
      include FormatterInterface

      def initialize(base_formatter, options = {})
        @base_formatter = base_formatter
        @options = options
        @show_debug = options.fetch(:debug, false)

        # Initialize state and display
        @state = TestRunState.empty
        @display = TTYStatusDisplay.new($stdout, options)

        # Only enable live status if TTY is available
        @live_status_enabled = @display.available?

        if @show_debug
          if @live_status_enabled
            $stderr.puts "DEBUG: LiveStatusFormatter: Live status ENABLED"
          else
            $stderr.puts "DEBUG: LiveStatusFormatter: Live status DISABLED (no TTY)"
          end
        end
      end

      def live_status_enabled?
        @live_status_enabled
      end

      # Override methods that need live status coordination
      def phase_header(message, file_count = nil, level = 0, io = $stdout)
        # Update state first
        @state = @state.update_from_event(:phase_header, message, file_count, level)

        # Let base formatter handle the output
        result = @base_formatter.phase_header(message, file_count, level, io)

        # Reserve status area for level 0 (main header)
        if level == 0 && @live_status_enabled
          if @show_debug
            $stderr.puts "DEBUG: LiveStatusFormatter: Reserving status area"
          end
          @display.reserve_status_area
          @display.update_status(@state)
        end

        result
      end

      def file_parsed(file_path, test_count, io = $stdout, setup_present: false, teardown_present: false)
        @base_formatter.file_parsed(file_path, test_count, io, setup_present: setup_present, teardown_present: teardown_present)
      end

      def file_execution_start(file_path, test_count, context_mode, io = $stdout)
        @base_formatter.file_execution_start(file_path, test_count, context_mode, io)
      end

      def file_start(file_path, context_info = {}, io = $stdout)
        @state = @state.update_from_event(:file_start, file_path, context_info)
        result = @base_formatter.file_start(file_path, context_info, io)
        @display.update_status(@state) if @live_status_enabled
        result
      end

      def file_end(file_path, context_info = {}, io = $stdout)
        @state = @state.update_from_event(:file_end, file_path, context_info)
        result = @base_formatter.file_end(file_path, context_info, io)
        @display.update_status(@state) if @live_status_enabled
        result
      end

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time, io = $stdout)
        @base_formatter.file_result(file_path, total_tests, failed_count, error_count, elapsed_time, io)
      end

      def test_start(test_case, index, total, io = $stdout)
        @state = @state.update_from_event(:test_start, test_case, index, total)
        result = @base_formatter.test_start(test_case, index, total, io)
        # Don't update status on test start - too frequent and causes flickering
        result
      end

      def test_end(test_case, index, total, io = $stdout)
        @state = @state.update_from_event(:test_end, test_case, index, total)
        result = @base_formatter.test_end(test_case, index, total, io)
        # Don't update status on test end - too frequent
        result
      end

      def test_result(result_packet, io = $stdout)
        @state = @state.update_from_event(:test_result, result_packet)
        result = @base_formatter.test_result(result_packet, io)
        @display.update_status(@state) if @live_status_enabled
        result
      end

      def test_output(test_case, output_text, io = $stdout)
        @base_formatter.test_output(test_case, output_text, io)
      end

      # Setup/teardown operations
      def setup_start(line_range, io = $stdout)
        @base_formatter.setup_start(line_range, io)
      end

      def setup_output(output_text, io = $stdout)
        @base_formatter.setup_output(output_text, io)
      end

      def teardown_start(line_range, io = $stdout)
        @base_formatter.teardown_start(line_range, io)
      end

      def teardown_output(output_text, io = $stdout)
        @base_formatter.teardown_output(output_text, io)
      end

      # Summary operations
      def batch_summary(failure_collector, io = $stdout)
        @base_formatter.batch_summary(failure_collector, io)
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io = $stdout)
        # Clear the live status area and disable live status for final output
        if @live_status_enabled
          if @show_debug
            $stderr.puts "DEBUG: LiveStatusFormatter: Clearing status area for final summary"
          end
          @display.clear_status_area

          # Temporarily disable live status so final output goes directly to terminal
          @live_status_enabled = false
        end

        # Let base formatter handle the final summary normally
        @base_formatter.grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io)
      end

      # Override output methods to coordinate with status display
      def raw_output(text, io = $stdout)
        if @live_status_enabled
          @display.write_scrolling(text)
        else
          @base_formatter.raw_output(text, io)
        end
      end

      def error_message(message, backtrace = nil, io = $stdout)
        if @live_status_enabled
          # Format error message and write through display
          formatted = if @base_formatter.respond_to?(:format_error_message)
            @base_formatter.format_error_message(message, backtrace)
          else
            error_text = "ERROR: #{message}\n"
            if backtrace && @show_debug
              error_text += backtrace.first(3).map { |line| "  #{line.chomp}" }.join("\n") + "\n"
            end
            error_text
          end
          @display.write_scrolling(formatted)
        else
          @base_formatter.error_message(message, backtrace, io)
        end
      end

      def debug_info(message, level = 0, io = $stdout)
        return unless @show_debug

        if @live_status_enabled
          # Format debug message and write through display
          formatted = @base_formatter.respond_to?(:format_debug_message) ?
            @base_formatter.format_debug_message(message, level) :
            @base_formatter.indent_text("DEBUG: #{message}", level) + "\n"
          @display.write_scrolling(formatted)
        else
          @base_formatter.debug_info(message, level, io)
        end
      end

      def trace_info(message, level = 0, io = $stdout)
        @base_formatter.trace_info(message, level, io)
      end

      def separator(style = :light, io = $stdout)
        @base_formatter.separator(style, io)
      end

      # Provide access to the wrapped formatter for capability checks
      def base_formatter
        @base_formatter
      end

      def live_status_capabilities
        {
          supports_coordination: true,
          output_frequency: @base_formatter.respond_to?(:live_status_capabilities) ?
            @base_formatter.live_status_capabilities[:output_frequency] : :medium,
          requires_tty: true
        }
      end

      # Method missing to ensure complete delegation with error handling
      def method_missing(method_name, *args, **kwargs, &block)
        if @base_formatter.respond_to?(method_name)
          begin
            @base_formatter.send(method_name, *args, **kwargs, &block)
          rescue ArgumentError => e
            if @show_debug
              $stderr.puts "DEBUG: LiveStatusFormatter delegation error for #{method_name}: #{e.message}"
              $stderr.puts "  args: #{args.inspect}"
              $stderr.puts "  kwargs: #{kwargs.inspect}"
            end
            # Try without kwargs if that was the issue
            if kwargs.any?
              @base_formatter.send(method_name, *args, &block)
            else
              raise
            end
          end
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @base_formatter.respond_to?(method_name, include_private) || super
      end
    end
  end
end
