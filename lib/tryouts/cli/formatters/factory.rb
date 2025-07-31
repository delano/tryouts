# lib/tryouts/cli/formatters/factory.rb

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

        case format
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
        when :live
          LiveFormatter.new(options)
        else
          CompactFormatter.new(options) # Default to compact
        end
      end

      class << self
        private

        def determine_format_from_flags(options)
          return :quiet if options[:quiet]
          return :verbose if options[:verbose]
          return :live if options[:live]

          :compact # Default
        end
      end
    end
  end
end
