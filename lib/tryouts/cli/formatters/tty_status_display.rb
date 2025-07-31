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
        @io = io
        @available = check_tty_availability
        @show_debug = options.fetch(:debug, false)

        if @available
          @cursor = TTY::Cursor
          @pastel = Pastel.new
          @status_active = false
        end
      end

      def available?
        @available
      end

      def reserve_status_area
        return unless @available && !@status_active

        # Move cursor down to make space for status area
        STATUS_LINES.times { @io.print "\n" }

        # Move cursor back up to content area
        @io.print @cursor.up(STATUS_LINES)

        @status_active = true
      end

      def write_scrolling(text)
        return @io.print(text) unless @available

        if @status_active
          # Save cursor, write content, restore cursor for status area
          @io.print @cursor.save
          @io.print text
          @io.print @cursor.restore
        else
          @io.print text
        end
      end

      def update_status(state)
        return unless @available && @status_active

        # Save current cursor position
        @io.print @cursor.save

        # Move to status area (bottom of screen)
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Clear status area
        STATUS_LINES.times do
          @io.print @cursor.clear_line
          @io.print @cursor.down(1) if STATUS_LINES > 1
        end

        # Move back to start of status area
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)

        # Write status content
        write_status_content(state)

        # Restore cursor position
        @io.print @cursor.restore
        @io.flush
      end

      def clear_status_area
        return unless @available && @status_active

        # Move to status area and clear it
        @io.print @cursor.move_to(0, TTY::Screen.height - STATUS_LINES + 1)
        STATUS_LINES.times do
          @io.print @cursor.clear_line
          @io.print @cursor.down(1)
        end

        @status_active = false
      end

      private

      def check_tty_availability
        # Check if we have a real TTY
        return false unless @io.respond_to?(:tty?) && @io.tty?

        # Check if we can get screen dimensions
        return false unless TTY::Screen.width > 0 && TTY::Screen.height > STATUS_LINES + 5

        # Check if TERM environment variable suggests terminal capabilities
        term = ENV['TERM']
        return false if term.nil? || term == 'dumb'

        # Check if we're likely in a CI environment (common CI env vars)
        ci_vars = %w[CI CONTINUOUS_INTEGRATION BUILD_NUMBER JENKINS_URL GITHUB_ACTIONS]
        return false if ci_vars.any? { |var| ENV[var] }

        true
      rescue StandardError => e
        # If any TTY detection fails, assume not available
        if @show_debug
          @io.puts "TTY detection failed: #{e.message}"
        end
        false
      end

      def write_status_content(state)
        return unless @available

        # Line 1: Empty separator line
        @io.print "\n"

        # Line 2: Current progress
        if state.current_file
          current_info = "Running: #{state.current_file}"
          current_info += " → #{state.current_test}" if state.current_test
          @io.print current_info
        else
          @io.print "Ready"
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
        files_info = "Files: #{state.files_completed}"
        files_info += "/#{state.total_files}" if state.total_files > 0
        files_info += " completed"
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
      def initialize(io = $stdout, options = {})
        @io = io
      end

      def available?; false; end
      def reserve_status_area; end
      def write_scrolling(text); @io.print(text); end
      def update_status(state); end
      def clear_status_area; end
    end
  end
end
