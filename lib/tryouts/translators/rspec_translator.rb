# lib/tryouts/translators/rspec_translator.rb
#
# frozen_string_literal: true

require_relative 'eval_source'
require_relative 'example_run'
require_relative 'generated_code'

class Tryouts
  module Translators
    # Translates Tryouts test files to RSpec format
    #
    # IMPORTANT: Context Mode Differences
    # ==================================
    #
    # Tryouts supports two context modes that behave differently than RSpec:
    #
    # 1. Tryouts Shared Context (default):
    #    - Setup runs once, all tests share the same context object
    #    - Tests can modify variables/state and affect subsequent tests
    #    - Behaves like a Ruby script executing top-to-bottom
    #    - Designed for documentation-style tests where examples build on each other
    #
    # 2. Tryouts Fresh Context (--no-shared-context):
    #    - Setup @instance_variables are copied to each test's fresh context
    #    - Tests are isolated but inherit setup state
    #    - Similar to RSpec's before(:each) but with setup state inheritance
    #
    # RSpec Translation Behavior:
    # ===========================
    # - Uses before(:all) for setup code (closest equivalent to shared context)
    # - Each 'it' block gets fresh context (RSpec standard)
    # - Tests that rely on shared state between test cases WILL FAIL
    # - This is intentional and reveals inappropriate test dependencies
    #
    # Example that works in Tryouts shared mode but fails in RSpec:
    #   ## TEST 1
    #   @counter = 1
    #   @counter
    #   #=> 1
    #
    #   ## TEST 2
    #   @counter += 1  # Will be nil in RSpec, causing failure
    #   @counter
    #   #=> 2
    #
    # Recommendation: Write tryouts tests that work in fresh context mode
    # if you plan to use RSpec translation.
    class RSpecTranslator
      def initialize
        require 'rspec/core'
      rescue LoadError
        raise 'RSpec gem is required for RSpec translation'
      end

      def translate(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')

        RSpec.describe "Tryouts: #{file_basename}" do
          # Setup before all tests
          if testrun.setup && !testrun.setup.empty?
            before(:all) do
              ExampleRun.top_level_binding(self).eval(*EvalSource.section(testrun, testrun.setup))
            end
          end

          # Generate test cases
          testrun.test_cases.each do |test_case|
            # Orphan blocks become plain statements in the describe body, in source order
            if test_case.is_a?(Tryouts::OrphanBlock)
              unless test_case.empty?
                ExampleRun.top_level_class_binding(self).eval(*EvalSource.section(testrun, test_case))
              end
              next
            end

            # Every test case is an example, as in direct mode: one with no
            # code (a detached expectation) fails there and here.
            it test_case.description do
              ExampleRun.new(testrun, test_case, ExampleRun.top_level_binding(self)).each_outcome do |passed, message|
                expect(passed).to be_truthy, message
              end
            end
          end

          # Teardown after all tests. The constants the file defined stay
          # for the rest of the run, as in direct mode.
          if testrun.teardown && !testrun.teardown.empty?
            after(:all) do
              ExampleRun.top_level_binding(self).eval(*EvalSource.section(testrun, testrun.teardown))
            end
          end
        end
      end

      def generate_code(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        lines         = [*testrun.magic_comments] # magic comments only apply at the top of a file

        lines << ''
        lines << "RSpec.describe '#{file_basename}' do"

        if testrun.setup && !testrun.setup.empty?
          lines << '  before(:all) do'
          testrun.setup.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << '  end'
          lines << ''
        end

        testrun.test_cases.each_with_index do |test_case, _index|
          # Orphan blocks become plain statements in the describe body, in source order
          if test_case.is_a?(Tryouts::OrphanBlock)
            unless test_case.empty?
              test_case.code.lines.each { |line| lines << "  #{line.chomp}" }
              lines << ''
            end
            next
          end

          lines << "  it #{test_case.description.inspect} do"
          lines.concat(GeneratedCode.result_lines(test_case))
          test_case.expectations.each do |expectation|
            lines.concat(assertion_lines(test_case, expectation))
          end
          lines << '  end'
          lines << ''
        end

        if testrun.teardown && !testrun.teardown.empty?
          lines << '  after(:all) do'
          testrun.teardown.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << '  end'
        end

        lines << 'end'
        lines.join("\n")
      end

      private

      # The RSpec expectations for one tryouts expectation, with the same
      # pass/fail as direct mode (see GeneratedCode)
      def assertion_lines(test_case, expectation)
        expr = GeneratedCode.expression(expectation)
        case expectation.type
        when :regular then ["    expect(result).to eq(#{expr})"]
        when :true then ["    expect(#{expr}).to be(true)"] # rubocop:disable Lint/BooleanSymbol
        when :false then ["    expect(#{expr}).to be(false)"] # rubocop:disable Lint/BooleanSymbol
        when :boolean then ["    expect([true, false]).to include(#{expr})"]
        when :result_type then ["    expect(result).to be_a(#{expr})"]
        when :regex_match then ["    expect(result.to_s).to match(#{expr})"]
        when :non_nil
          # Not nil and, where the code may have rescued one, no error
          [*('    expect(error).to be_nil' if GeneratedCode.rescues?(test_case)), '    expect(result).not_to be_nil']
        when :exception
          # The expression's value decides, as in direct mode: a Module is
          # what the error must be a kind of, anything else must be truthy
          ["    expected = #{expr}",
           '    expect(error).not_to be_nil',
           '    if expected.is_a?(Module)',
           '      expect(error).to be_a(expected)',
           '    else',
           '      expect(expected).to be_truthy',
           '    end']
        else
          ["    RSpec::Expectations.fail_with(#{GeneratedCode.untranslated_message(test_case, expectation, 'RSpec').inspect})"]
        end
      end
    end
  end
end
