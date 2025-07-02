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
        case options[:format]&.to_sym
        when :verbose
          if options[:fails_only]
            VerboseFailsFormatter.new(options)
          else
            VerboseFormatter.new(options)
          end
        when :compact
          CompactFormatter.new(options)
        when :quiet
          QuietFormatter.new(options)
        else
          VerboseFormatter.new(options) # Default to verbose
        end
      end
    end
  end
end
