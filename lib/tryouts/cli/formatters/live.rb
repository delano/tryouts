# lib/tryouts/cli/formatters/live.rb

require 'tty-cursor'
require 'tty-screen'
require 'pastel'
require 'io/console'

class Tryouts
  class CLI
    # Live formatter with fixed status display (RSpec-style)
    class LiveFormatter
      include FormatterInterface

      STATUS_LINES = 5  # Lines reserved for fixed status display (4 content + 1 separator)

      def initialize(options = {})
        @options    = options
        @show_debug = options.fetch(:debug, false)
        @show_trace = options.fetch(:trace, false)

        # TTY availability is now determined externally by FormatterFactory
        # If we get here, TTY is available - no fallback needed
        @tty_available = options.fetch(:tty_available, true)

        # Live state tracking
        @running_totals = {
          total_tests: 0,
          passed: 0,
          failed: 0,
          errors: 0,
          files_completed: 0,
          total_files: 0,
          current_file: nil,
          current_test: nil,
          start_time: nil,
        }

        @status_active = false
        @cursor        = TTY::Cursor
        @pastel        = Pastel.new
      end

      # Phase-level output
      def phase_header(message, file_count = nil, level = 0, io = $stdout)
        case level
        when 0
          @running_totals[:total_files] = file_count if file_count
          @running_totals[:start_time]  = Time.now
          write_scrolling("#{message}\n", io)
          reserve_status_area(io)
        when 1
          # Execution phase - don't show header or update status
          nil
        else
          write_scrolling(indent_text(message, level - 1) + "\n", io)
        end
      end

      # File-level operations
      def file_start(file_path, context_info = {}, io = $stdout)
        @running_totals[:current_file] = Console.pretty_path(file_path)
        update_status(io)
      end

      def file_end(file_path, context_info = {}, io = $stdout)
        @running_totals[:files_completed] += 1
        @running_totals[:current_file]     = nil
        update_status(io)
      end

      def file_parsed(file_path, test_count, io = $stdout, setup_present: false, teardown_present: false)
        return unless @show_debug

        extras = []
        extras << 'setup' if setup_present
        extras << 'teardown' if teardown_present
        suffix = extras.empty? ? '' : " +#{extras.join(',')}"
        write_scrolling("  Parsed #{test_count} tests#{suffix}\n", io)
      end

      def file_execution_start(file_path, test_count, context_mode, io = $stdout)
        # Don't output "Running:" messages to scrolling area - this info is in the live status
        # Just update the status footer
        update_status(io)
      end

      def file_result(file_path, total_tests, failed_count, error_count, elapsed_time, io = $stdout)
        # File completed - show result in scrolling area
        issues_count = failed_count + error_count
        passed_count = total_tests - issues_count

        if issues_count > 0
          status  = @pastel.red('✗')
          details = "#{passed_count}/#{total_tests} passed"
        else
          status  = @pastel.green('✓')
          details = "#{total_tests} passed"
        end

        details_parts = [details]
        details_parts << "#{failed_count} failed" if failed_count > 0
        details_parts << "#{error_count} errors" if error_count > 0

        time_str = elapsed_time ? " #{format_timing(elapsed_time)}" : ''
        write_scrolling("  #{status} #{details_parts.join(', ')}#{time_str}\n", io)

        update_status(io)
      end

      # Test-level operations
      def test_start(test_case, index, total, io = $stdout)
        desc                           = test_case.description.to_s
        desc                           = "test #{index}" if desc.empty?
        @running_totals[:current_test] = desc
        # Don't update status on test start - too frequent
      end

      def test_end(_test_case, _index, _total, io = $stdout)
        @running_totals[:current_test] = nil
        # Don't update status on test end - too frequent
      end

      def test_result(result_packet, io = $stdout)
        @running_totals[:total_tests] += 1

        case result_packet.status
        when :passed
          @running_totals[:passed] += 1
        when :failed
          @running_totals[:failed] += 1
          show_failure_in_scrolling_area(result_packet, io)
        when :error
          @running_totals[:errors] += 1
          show_error_in_scrolling_area(result_packet, io)
        end

        update_status(io)
      end

      def test_output(_test_case, output_text, io = $stdout)
        # Only show output for failed tests or in debug mode
        return if output_text.nil? || output_text.strip.empty?
        return unless @show_debug

        write_scrolling("    Output: #{output_text.lines.count} lines\n", io)
      end

      # Setup/teardown operations
      def setup_start(line_range, io = $stdout)
        # No output for setup start in live mode
      end

      def setup_output(output_text, io = $stdout)
        return if output_text.strip.empty?
        return unless @show_debug

        lines = output_text.lines.count
        write_scrolling("    Setup output (#{lines} lines)\n", io)
      end

      def teardown_start(line_range, io = $stdout)
        # No output for teardown start in live mode
      end

      def teardown_output(output_text, io = $stdout)
        return if output_text.strip.empty?
        return unless @show_debug

        lines = output_text.lines.count
        write_scrolling("    Teardown output (#{lines} lines)\n", io)
      end

      # Summary operations
      def batch_summary(total_tests, failed_count, elapsed_time, io = $stdout)
        # Live mode handles this through continuous status updates
      end

      def grand_total(total_tests, failed_count, error_count, successful_files, total_files, elapsed_time, io = $stdout)
        clear_status_area(io)
        @status_active = false

        # Show final summary in traditional format since live status is cleared
        issues_count = failed_count + error_count
        passed_count = total_tests - issues_count

        if issues_count > 0
          status = @pastel.red("✗ #{passed_count}/#{total_tests} passed")
          details = []
          details << @pastel.red("#{failed_count} failed") if failed_count > 0
          details << @pastel.yellow("#{error_count} errors") if error_count > 0
          write_scrolling("#{status}, #{details.join(', ')}\n", io)
        else
          status = @pastel.green("✓ All #{total_tests} tests passed")
          write_scrolling("#{status}\n", io)
        end

        # File summary
        if total_files > 1
          write_scrolling("Files: #{successful_files}/#{total_files} completed\n", io)
        end

        # Timing
        write_scrolling("Time: #{format_timing(elapsed_time)}\n", io)
      end

      # Debug and diagnostic output
      def debug_info(message, level = 0, io = $stdout)
        return unless @show_debug

        write_scrolling(indent_text("DEBUG: #{message}", level) + "\n", io)
      end

      def trace_info(message, level = 0, io = $stdout)
        return unless @show_trace

        write_scrolling(indent_text("TRACE: #{message}", level) + "\n", io)
      end

      def error_message(message, backtrace = nil, io = $stdout)
        write_scrolling(@pastel.red("ERROR: #{message}") + "\n", io)

        return unless backtrace && @show_debug

        backtrace.first(3).each do |line|
          write_scrolling(indent_text(line.chomp, 1) + "\n", io)
        end
      end

      # Utility methods
      def raw_output(text, io = $stdout)
        return if text.nil? || text.strip.empty?
        write_scrolling(text + "\n", io)
      end

      def separator(style = :light, io = $stdout)
        # In live mode, we don't show separators as they interfere with clean output
        # The live status provides separation
      end

      private

      def indent_text(text, level)
        ('  ' * level) + text
      end

      def reserve_status_area(io)
        return unless @tty_available && !@status_active

        # Move cursor down to make space for status area
        STATUS_LINES.times { io.print "\n" }

        # Move cursor back up to content area
        io.print @cursor.up(STATUS_LINES)

        @status_active = true
        update_status(io)
      end

      def write_scrolling(text, io)
        return unless @tty_available

        if @status_active
          # Save cursor, write content, restore cursor for status area
          io.print @cursor.save
          io.print text
          io.print @cursor.restore
        else
          io.print text
        end
      end

      def update_status(io)
        return unless @tty_available && @status_active

        # Save current cursor position
        io.print @cursor.save

        # Move to status area (bottom of screen)
        io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Clear status area
        STATUS_LINES.times do
          io.print @cursor.clear_line
          io.print @cursor.down(1) if STATUS_LINES > 1
        end

        # Move back to start of status area
        io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Write status content
        write_status_content(io)

        # Restore cursor position
        io.print @cursor.restore
        io.flush
      end

      def write_status_content(io)
        totals  = @running_totals
        elapsed = totals[:start_time] ? Time.now - totals[:start_time] : 0

        # Line 1: Empty separator line
        io.print "\n"

        # Line 2: Current progress
        if totals[:current_file]
          current_info  = "Running: #{totals[:current_file]}"
          current_info += " → #{totals[:current_test]}" if totals[:current_test]
          io.print current_info
        else
          io.print "Ready"
        end
        io.print "\n"

        # Line 3: Test counts
        parts = []
        parts << @pastel.green("#{totals[:passed]} passed") if totals[:passed] > 0
        parts << @pastel.red("#{totals[:failed]} failed") if totals[:failed] > 0
        parts << @pastel.yellow("#{totals[:errors]} errors") if totals[:errors] > 0

        if parts.any?
          io.print "Tests: #{parts.join(', ')}"
        else
          io.print 'Tests: 0 run'
        end
        io.print "\n"

        # Line 4: File progress
        files_info  = "Files: #{totals[:files_completed]}"
        files_info += "/#{totals[:total_files]}" if totals[:total_files] > 0
        files_info += " completed"
        io.print files_info
        io.print "\n"

        # Line 5: Timing
        io.print "Time: #{format_timing(elapsed)}"
      end

      def clear_status_area(io)
        return unless @tty_available && @status_active

        # Move to status area and clear it
        io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)
        STATUS_LINES.times do
          io.print @cursor.clear_line
          io.print @cursor.down(1)
        end
      end

      def show_failure_in_scrolling_area(result_packet, io)
        test_case = result_packet.test_case
        desc      = test_case.description.to_s
        desc      = 'unnamed test' if desc.empty?

        status = @pastel.red('✗')
        write_scrolling("    #{status} #{desc}\n", io)

        # Show minimal failure info
        if result_packet.actual_results.any?
          failure_info = "      got: #{result_packet.first_actual.inspect}"
          write_scrolling("#{failure_info}\n", io)
        end
      end

      def show_error_in_scrolling_area(result_packet, io)
        test_case = result_packet.test_case
        desc      = test_case.description.to_s
        desc      = 'unnamed test' if desc.empty?

        status = @pastel.yellow('⚠')
        write_scrolling("    #{status} #{desc}\n", io)

        # Show error info
        if result_packet.error_info
          error_info = "      #{result_packet.error_info}"
          write_scrolling("#{error_info}\n", io)
        end
      end

      def format_timing(elapsed_time)
        if elapsed_time < 0.001
          "#{(elapsed_time * 1_000_000).round}μs"
        elsif elapsed_time < 1
          "#{(elapsed_time * 1000).round}ms"
        else
          "#{elapsed_time.round(2)}s"
        end
      end
    end
  end
end
