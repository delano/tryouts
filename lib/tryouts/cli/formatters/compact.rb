# lib/tryouts/cli/formatters/compact.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    # Compact single-line formatter focused on results
    class CompactFormatter
      include FormatterInterface

      def initialize(options = {})
        super
        @show_debug  = options.fetch(:debug, false)
        @show_trace  = options.fetch(:trace, false)
        @show_passed = options.fetch(:show_passed, true)
        @show_stack_traces = options.fetch(:stack_traces, false) || options.fetch(:debug, false)
        # Under --parallel several files run at once. Each file's lines are
        # held until its result line, then written together.
        @file_buffers      = options[:parallel] ? {} : nil
        @buffers_lock      = Mutex.new
      end

      # Phase-level output - minimal for compact mode
      def phase_header(message, file_count: nil)
        # Show processing header but skip execution phase headers to avoid empty lines
        if message.include?('PROCESSING')
          # Main processing header
          text = file_count ? "#{message}" : "#{message}..."
          @stderr.puts text
        elsif !message.include?('EXECUTING')
          # Other phase headers with minimal formatting
          @stderr.puts message
        end
      end

      # File-level operations - compact single lines
      def file_start(file_path, context_info: {})
        # Output handled in file_execution_start for compact mode
      end

      def file_parsed(_file_path, test_count:, setup_present: false, teardown_present: false)
        # Don't show parsing info in compact mode unless debug
        return unless @show_debug

        extras = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        suffix = extras.empty? ? '' : " +#{extras.join(',')}"

        @stderr.puts indent_text("Parsed #{test_count} tests#{suffix}", 1)
      end

      def parser_warnings(file_path, warnings:)
        return if warnings.empty? || !@options.fetch(:warnings, true)

        @stderr.puts
        @stderr.puts Console.color(:yellow, "Warnings:")
        warnings.each do |warning|
          @stderr.puts "  #{Console.pretty_path(file_path)}:#{warning.line_number}: #{warning.message}"
        end
      end

      def file_execution_start(file_path, test_count:, context_mode:)
        pretty_path = Console.pretty_path(file_path)
        file_line(file_path)
        file_line(file_path, "#{pretty_path}: #{test_count} tests")
      end

      # Summary operations - show failure summary
      def batch_summary(failure_collector)
        return unless failure_collector.any_failures?

        puts
        puts separator
        puts Console.color(:red, 'Failed Tests:')
        puts

        # Number failures sequentially across all files instead of per-file
        failure_number = 1
        failure_collector.failures_by_file.each do |file_path, failures|
          failures.each do |failure|
            pretty_path = Console.pretty_path(file_path)

            # Include line number with file path for easy copying/clicking
            location = "#{pretty_path}:#{failure.line_number + 1}"

            puts "  #{failure_number}) #{location}"
            puts "    #{Console.color(:red, '✗')} #{failure.description}"
            puts "      #{failure.failure_reason}"
            puts
            failure_number += 1
          end
        end
      end

      def file_result(file_path, total_tests:, failed_count:, error_count:, elapsed_time: nil, section_failures: [], not_run: 0)
        issues_count = failed_count + error_count + section_failures.size + not_run
        passed_count = total_tests - failed_count - error_count
        details = []

        if issues_count > 0
          status = Console.color(:red, '✗')
          details << "#{passed_count}/#{total_tests + not_run} passed"
        else
          status = Console.color(:green, '✓')
          details << "#{total_tests} passed"
        end

        if error_count > 0
          details << "#{error_count} errors"
        end

        if failed_count > 0
          details << "#{failed_count} failed"
        end

        details << "#{not_run} not run" if not_run > 0
        details.concat(section_failure_details(section_failures))

        time_str = format_timing(elapsed_time)
        file_line(file_path, "  #{status} #{details.join(', ')}#{time_str}")
        flush_file(file_path)
      end

      # A file that stopped with an error still shows what it printed
      def file_failure(file_path, message, backtrace: nil)
        flush_file(file_path)
        super
      end

      # Test-level operations - only show in debug mode for compact
      def test_start(test_case:, index:, total:)
        return unless @show_debug

        desc = test_case.description.to_s
        desc = "test #{index}" if desc.empty?

        file_line(test_case.path, "    Running: #{desc}")
      end

      def test_result(result_packet)
        # Only show failed tests in compact mode unless show_passed is true
        return if result_packet.passed? && !@show_passed

        test_case = result_packet.test_case
        desc = test_case.description.to_s
        desc = 'unnamed test' if desc.empty?
        path = test_case.path

        case result_packet.status
        when :passed
          status = Console.color(:green, '✓')
          file_line(path, indent_text("#{status} #{desc}", 1))
        when :failed
          status = Console.color(:red, '✗')
          file_line(path, indent_text("#{status} #{desc}", 1))

          # Show minimal context for failures
          unless result_packet.actual_results.empty?
            failure_info = "got: #{result_packet.failed_actual.inspect}"
            file_line(path, indent_text("    #{failure_info}", 1))
          end

          # Show 1-2 lines of test context if available
          if test_case.source_lines && test_case.source_lines.size <= 3
            test_case.source_lines.each do |line|
              next if line.strip.empty? || line.strip.start_with?('#')

              file_line(path, indent_text("    #{line.strip}", 1))
              break # Only show first relevant line
            end
          end
        when :skipped
          status = Console.color(:yellow, '-')
          file_line(path, indent_text("#{status} #{desc}", 1))
        else
          status = '?'
          file_line(path, indent_text("#{status} #{desc}", 1))
        end
      end

      def test_output(test_case:, output_text:, result_packet:)
        # In compact mode, only show output for failed tests and only if debug mode is enabled
        return if output_text.nil? || output_text.strip.empty?
        return unless @show_debug
        return if result_packet.passed?

        file_line(test_case.path, "    Output: #{output_text.lines.count} lines")
        if output_text.lines.count <= 3
          output_text.lines.each do |line|
            file_line(test_case.path, "      #{line.chomp}")
          end
        else
          file_line(test_case.path, "      #{output_text.lines.first.chomp}")
          file_line(test_case.path, "      ... (#{output_text.lines.count - 2} more lines)")
          file_line(test_case.path, "      #{output_text.lines.last.chomp}")
        end
      end

      # Setup/teardown operations - minimal output
      def setup_start(line_range:)
        # No file setup start output for compact
      end

      def setup_output(output_text)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        @stderr.puts "    Setup output (#{lines} lines)"
      end

      def teardown_start(line_range:)
        return unless @show_debug

        @stderr.puts '    Teardown...'
      end

      def teardown_output(output_text)
        return if output_text.strip.empty?
        return unless @show_debug

        # In compact mode, just show that there was output
        lines = output_text.lines.count
        @stderr.puts "    Teardown output (#{lines} lines)"
      end

      def grand_total(total_tests:, failed_count:, error_count:, successful_files:, total_files:, elapsed_time:, not_run: 0)
        @stderr.puts

        issues_count = failed_count + error_count
        if issues_count > 0
          passed = [total_tests - issues_count, 0].max  # Ensure passed never goes negative
          details = []
          details << "#{failed_count} failed" if failed_count > 0
          details << "#{error_count} errors" if error_count > 0
          result = Console.color(:red, "#{details.join(', ')}, #{passed} passed#{not_run_detail(not_run)}")
        elsif not_run > 0
          result = Console.color(:red, "#{total_tests} tests passed#{not_run_detail(not_run)}")
        else
          result = Console.color(:green, "#{total_tests} tests passed")
        end

        time_str = format_timing(elapsed_time)

        @stderr.puts "#{result}#{time_str}"
        @stderr.puts "#{successful_files} of #{total_files} files passed"
      end

      # Debug and diagnostic output - minimal in compact mode
      def debug_info(message, level: 0)
        return unless @show_debug

        @stderr.puts indent_text("DEBUG: #{message}", level)
      end

      def trace_info(message, level: 0)
        return unless @show_trace

        @stderr.puts indent_text("TRACE: #{message}", level)
      end

      def error_message(message, backtrace: nil)
        @stderr.puts Console.color(:red, "ERROR: #{message}")

        return unless backtrace && @show_stack_traces

        Console.pretty_backtrace(backtrace, limit: 3).each do |line|
          @stderr.puts indent_text(line, 1)
        end
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # Compact can work with coordinated output
          output_frequency: :medium,       # Outputs at medium frequency
          requires_tty: false,             # Works without TTY
        }
      end

      private

      # A line of one file's output: written now, or under --parallel held
      # until the file's result line
      def file_line(file_path, text = '')
        return puts(text) unless @file_buffers

        @buffers_lock.synchronize { (@file_buffers[file_path] ||= +'') << "#{text}\n" }
      end

      # Writes the lines held for the file in one piece
      def flush_file(file_path)
        return unless @file_buffers

        text = @buffers_lock.synchronize { @file_buffers.delete(file_path) }
        write(text) if text
      end
    end

    # Compact formatter that only shows failures and errors
    class CompactFailsFormatter < CompactFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def test_result(result_packet)
        # Only show failed/error tests
        return if result_packet.passed?

        super
      end

      def live_status_capabilities
        {
          supports_coordination: true,     # Compact can work with coordinated output
          output_frequency: :low,          # Outputs infrequently, mainly summaries
          requires_tty: false,             # Works without TTY
        }
      end
    end
  end
end
