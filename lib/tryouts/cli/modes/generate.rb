# lib/tryouts/cli/modes/generate.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    class GenerateMode
      def initialize(file, testrun, options, output_manager, translator)
        @file           = file
        @testrun        = testrun
        @options        = options
        @output_manager = output_manager
        @translator     = translator
      end

      def handle
        @output_manager.raw("# Generated #{@options[:framework]} code for #{@file}")
        @output_manager.raw("# Updated: #{Time.now}")
        @output_manager.raw(@translator.generate_code(@testrun))
        @output_manager.raw('')
      end
    end
  end
end
