# lib/tryouts/cli/formatters/tty_status_display.rb

require 'tty-cursor'
require 'tty-screen'
require 'pastel'
require 'io/console'

class Tryouts
  class CLI
    # Encapsulates TTY manipulation for live status display with fallback
    class TTYStatusDisplay
      STATUS_LINES = 5  # Lines reserved for fixed status display (4 content + 1 separator)

      def initialize(io = $stdout, options = {})
        @io         = io
        @available  = check_tty_availability
        @show_debug = options.fetch(:debug, false)

        return unless @available

        @cursor        = TTY::Cursor
        @pastel        = Pastel.new
        @status_active = false
      end

      def available?
        @available
      end

      def reserve_status_area
        return unless @available && !@status_active

        # Simply print empty lines to push content up and make room at bottom
        STATUS_LINES.times { @io.print "\n" }

        @status_active = true
      end

      def write_scrolling(text)
        return @io.print(text) unless @available

        # Always write content normally - the status will be updated separately
        @io.print text
      end

      def update_status(state)
        return unless @available && @status_active

        # Move to status area (bottom of screen) and update in place
        current_row, current_col = get_cursor_position

        # Move to status area at bottom
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Clear and write status content
        STATUS_LINES.times do
          @io.print @cursor.clear_line
          @io.print @cursor.down(1) unless STATUS_LINES == 1
        end

        # Move back to start of status area and write content
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)
        write_status_content(state)

        # Move cursor back to where content should continue (just before status area)
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES)
        @io.flush
      end

      def clear_status_area
        return unless @available && @status_active

        # Move to status area and clear it completely - start from first status line
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Clear each line thoroughly
        STATUS_LINES.times do |i|
          @io.print @cursor.clear_line
          @io.print @cursor.down(1) if i < STATUS_LINES - 1  # Don't go down after last line
        end

        # Move cursor to a clean area for final output - position it well above the cleared area
        # This ensures no interference with the cleared status content
        target_row = TTY::Screen.height - STATUS_LINES - 2  # Leave some buffer space
        @io.print @cursor.move_to(0, target_row)
        @io.print "\n"  # Add a clean line for final output to start
        @io.flush

        @status_active = false
      end

      private

      def get_cursor_position
        # Simple approximation - in a real terminal this would query cursor position
        # For now, return reasonable defaults
        [10, 0]
      end

      def check_tty_availability
        # Check if we have a real TTY
        return false unless @io.respond_to?(:tty?) && @io.tty?

        # Check if we can get screen dimensions
        return false unless TTY::Screen.width > 0 && TTY::Screen.height > STATUS_LINES + 5

        # Check if TERM environment variable suggests terminal capabilities
        term = ENV.fetch('TERM', nil)
        return false if term.nil? || term == 'dumb'

        # Check if we're likely in a CI environment (common CI env vars)
        ci_vars = %w[CI CONTINUOUS_INTEGRATION BUILD_NUMBER JENKINS_URL GITHUB_ACTIONS]
        return false if ci_vars.any? { |var| ENV[var] }

        true
      rescue StandardError => ex
        # If any TTY detection fails, assume not available
        if @show_debug
          @io.puts "TTY detection failed: #{ex.message}"
        end
        false
      end

      def write_status_content(state)
        return unless @available

        # Line 1: Empty separator line
        @io.print "\n"

        # Line 2: Current progress
        if state.current_file
          current_info  = "Running: #{state.current_file}"
          current_info += " → #{state.current_test}" if state.current_test
          @io.print current_info
        else
          @io.print 'Ready'
        end
        @io.print "\n"

        # Line 3: Test counts
        parts = []
        parts << @pastel.green("#{state.passed} passed") if state.passed > 0
        parts << @pastel.red("#{state.failed} failed") if state.failed > 0
        parts << @pastel.yellow("#{state.errors} errors") if state.errors > 0

        if parts.any?
          @io.print "Tests: #{parts.join(', ')}"
        else
          @io.print 'Tests: 0 run'
        end
        @io.print "\n"

        # Line 4: File progress
        files_info  = "Files: #{state.files_completed}"
        files_info += "/#{state.total_files}" if state.total_files > 0
        files_info += ' completed'
        @io.print files_info
        @io.print "\n"

        # Line 5: Timing
        @io.print "Time: #{format_timing(state.elapsed_time)}"
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

    # No-op implementation for when TTY is not available
    class NoOpStatusDisplay
      def initialize(io = $stdout, _options = {})
        @io = io
      end

      def available? = false
      def reserve_status_area; end
      def write_scrolling(text) = @io.print(text)
      def update_status(state); end
      def clear_status_area; end
    end
  end
end
