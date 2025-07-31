# lib/tryouts/cli/formatters/factory.rb

require_relative '../tty_detector'
require_relative 'live_status_formatter'

class Tryouts
  class CLI
    # Factory for creating formatters and output managers
    class FormatterFactory
      def self.create_output_manager(options = {})
        formatter = create_formatter(options)
        OutputManager.new(formatter)
      end

      def self.create_formatter(options = {})
        # Map boolean flags to format symbols if format not explicitly set
        format = options[:format]&.to_sym || determine_format_from_flags(options)

        # Create base formatter first
        base_formatter = case format
        when :verbose
          if options[:fails_only]
            VerboseFailsFormatter.new(options)
          else
            VerboseFormatter.new(options)
          end
        when :compact
          if options[:fails_only]
            CompactFailsFormatter.new(options)
          else
            CompactFormatter.new(options)
          end
        when :quiet
          if options[:fails_only]
            QuietFailsFormatter.new(options)
          else
            QuietFormatter.new(options)
          end
        else
          CompactFormatter.new(options) # Default to compact
        end

        # Wrap with LiveStatusFormatter if requested
        if options[:live_status] || options[:live]
          # Check TTY support before creating live status wrapper
          tty_check = TTYDetector.check_tty_support(debug: options[:debug])

          if tty_check[:available]
            LiveStatusFormatter.new(base_formatter, options)
          else
            # Show warning and return base formatter
            if options[:debug]
              $stderr.puts "⚠️  Live status requested but not available: #{tty_check[:reason]}"
              $stderr.puts "   Continuing with #{base_formatter.class.name.split('::').last}."
            end
            base_formatter
          end
        else
          base_formatter
        end
      end

      class << self
        private

        def determine_format_from_flags(options)
          return :quiet if options[:quiet]
          return :verbose if options[:verbose]

          :compact # Default
        end
      end
    end
  end
end
