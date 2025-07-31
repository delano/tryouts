# lib/tryouts/cli/formatters/live_status_manager.rb

require_relative 'test_run_state'
require_relative 'tty_status_display'

class Tryouts
  class CLI
    # Centralized manager for live status display across all formatters
    # Replaces the decorator pattern with native integration
    class LiveStatusManager
      def initialize(formatter, options = {})
        @formatter  = formatter
        @enabled    = should_enable_live_status?(formatter, options)
        @show_debug = options.fetch(:debug, false)

        return unless @enabled

        # Initialize state tracking and display
        @state           = TestRunState.empty
        @display         = TTYStatusDisplay.new(@formatter.stdout, options)
        @status_reserved = false

        debug_log('LiveStatusManager: Enabled with native integration')
      end

      def enabled?
        @enabled
      end

      # Check if formatter and environment support live status
      def should_enable_live_status?(formatter, options)
        # Must be explicitly requested
        return false unless options[:live_status] || options[:live]

        # Check formatter capabilities
        capabilities = formatter.live_status_capabilities
        return false unless capabilities[:supports_coordination]

        # Check TTY availability
        require_relative '../tty_detector'
        tty_check = TTYDetector.check_tty_support(debug: options[:debug])

        unless tty_check[:available]
          debug_log("Live status disabled: #{tty_check[:reason]}")
          return false
        end

        true
      end

      # Main event handling - called by OutputManager for each formatter event
      def handle_event(event_type, *args, **)
        return unless @enabled

        # Update state based on the event
        @state = @state.update_from_event(event_type, *args, **)

        # Handle special events that need display coordination
        case event_type
        when :phase_header
          message, file_count, level = args
          if level == 0 && message.include?('PROCESSING') && file_count
            reserve_status_area
          end
        when :file_start, :file_end, :test_result
          update_display
        when :batch_summary
          # Clear status area before showing batch summary to avoid interference
          clear_status_area
        when :grand_total
          # Ensure status area is cleared (redundant safety check)
          clear_status_area if @status_reserved
        end
      end

      # Allow formatter to directly update live status (optional integration point)
      def update_status(state_updates = {})
        return unless @enabled

        @state = @state.with(**state_updates) unless state_updates.empty?
        update_display
      end

      # Output coordination methods
      def write_output
        return yield unless @enabled

        # If status area is reserved, coordinate the output
        if @status_reserved
          @display.write_scrolling(yield)
        else
          yield
        end
      end

      def write_string(text)
        return @formatter.stdout.print(text) unless @enabled

        if @status_reserved
          @display.write_scrolling(text)
        else
          @formatter.stdout.print(text)
        end
      end

      private

      def reserve_status_area
        return unless @enabled && @display.available?

        debug_log('Reserving status area for live display')
        @display.reserve_status_area
        @status_reserved = true
        update_display
      end

      def update_display
        return unless @enabled && @status_reserved

        @display.update_status(@state)
      end

      def clear_status_area
        return unless @enabled && @status_reserved

        debug_log('Clearing status area for final output')
        @display.clear_status_area
        @status_reserved = false
      end

      def debug_log(message)
        return unless @show_debug

        @formatter.stderr.puts "DEBUG: #{message}"
      end
    end
  end
end
