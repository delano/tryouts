# lib/tryouts/cli/tty_detector.rb
#
# frozen_string_literal: true

require 'tty-screen'

class Tryouts
  class CLI
    # TTY detection utility for determining live formatter availability
    module TTYDetector
      STATUS_LINES = 4  # Lines needed for live formatter status area

      # Check if TTY features are available for live formatting
      # Returns: { available: boolean, reason: string }
      def self.check_tty_support(debug: false)
        result = { available: false, reason: nil }

        # FORCE_LIVE override for testing
        if ENV['FORCE_LIVE'] == '1'
          debug_log('FORCE_LIVE=1 - forcing TTY support', debug)
          result[:available] = true
          result[:reason]    = 'Forced via FORCE_LIVE=1'
          return result
        end

        # Enhanced TTY detection to work with bundler and other execution contexts
        debug_log('TTY Detection:', debug)
        debug_log("  $stdout.tty? = #{$stdout.tty?}", debug)
        debug_log("  $stderr.tty? = #{$stderr.tty?}", debug)
        debug_log("  $stdin.tty? = #{$stdin.tty?}", debug)

        # Check if any standard stream is a TTY or if we have a controlling terminal
        has_tty = $stdout.tty? || $stderr.tty? || $stdin.tty?
        debug_log("  Combined streams TTY: #{has_tty}", debug)

        # Additional check: try to access controlling terminal directly
        unless has_tty
          begin
            # On Unix systems, /dev/tty represents the controlling terminal
            File.open('/dev/tty', 'r') { |f| has_tty = f.tty? }
            debug_log("  /dev/tty accessible: #{has_tty}", debug)
          rescue StandardError => ex
            debug_log("  /dev/tty error: #{ex.class}: #{ex.message}", debug)
          end
        end

        unless has_tty
          debug_log('  Final result: No TTY detected', debug)
          result[:reason] = 'No TTY detected (not running in terminal)'
          return result
        end

        # Skip in CI or dumb terminals
        if ENV['CI'] || ENV['TERM'] == 'dumb'
          debug_log("  CI or dumb terminal detected (CI=#{ENV['CI']}, TERM=#{ENV.fetch('TERM', nil)})", debug)
          result[:reason] = 'CI environment or dumb terminal detected'
          return result
        end

        # Test TTY gem availability and basic functionality
        begin
          height = TTY::Screen.height
          debug_log("  Screen height: #{height}, need minimum: #{STATUS_LINES + 5}", debug)

          if height < STATUS_LINES + 5  # Need minimum screen space
            debug_log('  Screen too small', debug)
            result[:reason] = "Terminal too small (#{height} lines < #{STATUS_LINES + 5} needed)"
            return result
          end

          # Test cursor control (basic check without actually saving)
          require 'tty-cursor'
          TTY::Cursor.save  # Just test that it exists

          debug_log('  TTY support enabled', debug)
          result[:available] = true
          result[:reason]    = 'TTY support available'
        rescue LoadError => ex
          debug_log("  TTY gem loading failed: #{ex.message}", debug)
          result[:reason] = "TTY gems not available: #{ex.message}"
        rescue StandardError => ex
          debug_log("  TTY setup failed: #{ex.class}: #{ex.message}", debug)
          result[:reason] = "TTY setup failed: #{ex.message}"
        end

        result
      end

      def self.debug_log(message, debug_enabled)
        $stderr.puts "DEBUG: #{message}" if debug_enabled
      end
    end
  end
end
