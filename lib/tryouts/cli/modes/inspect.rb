# lib/tryouts/cli/modes/inspect.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    class InspectMode
      def initialize(file, testrun, options, output_manager, translator)
        @file           = file
        @testrun        = testrun
        @options        = options
        @output_manager = output_manager
        @translator     = translator
      end

      def handle
        @output_manager.raw("Inspecting: #{@file}")
        @output_manager.separator(:heavy)
        @output_manager.raw("Found #{@testrun.total_tests} test cases")
        @output_manager.raw("Setup code: #{@testrun.setup.empty? ? 'None' : 'Present'}")
        @output_manager.raw("Teardown code: #{@testrun.teardown.empty? ? 'None' : 'Present'}")
        @output_manager.raw('')

        @testrun.test_cases.each_with_index do |tc, i|
          @output_manager.raw("Test #{i + 1}: #{tc.description}")
          @output_manager.raw("  Code lines: #{tc.code.lines.count}")
          @output_manager.raw("  Expectations: #{tc.expectations.size}")
          @output_manager.raw("  Range: #{tc.line_range}")
          @output_manager.raw('')
        end

        return unless @options[:framework] != :direct

        @output_manager.raw("Testing #{@options[:framework]} translation...")
        framework_klass    = TestRunner::FRAMEWORKS[@options[:framework]]
        inspect_translator = framework_klass.new

        translated_code = inspect_translator.generate_code(@testrun)
        @output_manager.raw("#{@options[:framework].to_s.capitalize} code generated (#{translated_code.lines.count} lines)")
        @output_manager.raw('')
      end
    end
  end
end
