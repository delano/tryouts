# lib/tryouts/translators/minitest_translator.rb
#
# frozen_string_literal: true

require_relative 'eval_source'
require_relative 'example_run'
require_relative 'generated_code'

class Tryouts
  module Translators
    # Translates Tryouts test files to Minitest format
    #
    # IMPORTANT: Context Mode Differences
    # ==================================
    #
    # Tryouts supports two context modes that behave differently than Minitest:
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
    #    - Similar to Minitest's setup method but with setup state inheritance
    #
    # Minitest Translation Behavior:
    # ==============================
    # - Uses setup method which runs before each test (Minitest standard)
    # - Each test method gets fresh context (Minitest standard)
    # - Tests that rely on shared state between test cases WILL FAIL
    # - This is intentional and reveals inappropriate test dependencies
    #
    # Example that works in Tryouts shared mode but fails in Minitest:
    #   ## TEST 1
    #   @counter = 1
    #   @counter
    #   #=> 1
    #
    #   ## TEST 2
    #   @counter += 1  # Will be reset to 1 by setup, then fail
    #   @counter
    #   #=> 2
    #
    # Recommendation: Write tryouts tests that work in fresh context mode
    # if you plan to use Minitest translation.
    class MinitestTranslator
      # Simple string parameterization for method names.
      #
      # Defined on the class because `translate` calls it from inside a
      # `Class.new(Minitest::Test) do ... end` block, where `self` is the
      # anonymous test class rather than the translator instance.
      def self.parameterize(string)
        string.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
      end

      def initialize
        require 'minitest/test'
      rescue LoadError
        raise 'Minitest gem is required for Minitest translation'
      end

      def translate(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        class_name    = "Test#{file_basename.gsub(/[^A-Za-z0-9]/, '')}"

        test_class = Class.new(Minitest::Test) do
          # Setup method
          if testrun.setup && !testrun.setup.empty?
            define_method(:setup) do
              ExampleRun.instance_binding(self).eval(*EvalSource.section(testrun, testrun.setup))
            end
          end

          # Generate test methods
          testrun.test_cases.each_with_index do |test_case, index|
            # Orphan blocks become plain statements in the class body, in source order
            if test_case.is_a?(Tryouts::OrphanBlock)
              unless test_case.empty?
                class_eval(*EvalSource.section(testrun, test_case))
              end
              next
            end

            # Every test case is a test, as in direct mode: one with no code
            # (a detached expectation) fails there and here.
            method_name = "test_#{index.to_s.rjust(3, '0')}_#{MinitestTranslator.parameterize(test_case.description)}"
            define_method(method_name) do
              ExampleRun.new(testrun, test_case, ExampleRun.instance_binding(self)).each_outcome do |passed, message|
                assert passed, message
              end
            end
          end

          # Teardown method
          if testrun.teardown && !testrun.teardown.empty?
            define_method(:teardown) do
              ExampleRun.instance_binding(self).eval(*EvalSource.section(testrun, testrun.teardown))
            end
          end
        end

        # Set the class name dynamically
        Object.const_set(class_name, test_class) unless Object.const_defined?(class_name)
        test_class
      end

      def generate_code(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        class_name    = "Test#{file_basename.gsub(/[^A-Za-z0-9]/, '')}"
        lines         = [*testrun.magic_comments] # magic comments only apply at the top of a file

        lines << ''
        lines << "require 'minitest/test'"
        lines << "require 'minitest/autorun'"
        lines << ''
        lines << "class #{class_name} < Minitest::Test"

        if testrun.setup && !testrun.setup.empty?
          lines << '  def setup'
          testrun.setup.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << '  end'
          lines << ''
        end

        testrun.test_cases.each_with_index do |test_case, index|
          # Orphan blocks become plain statements in the class body, in source order
          if test_case.is_a?(Tryouts::OrphanBlock)
            unless test_case.empty?
              test_case.code.lines.each { |line| lines << "  #{line.chomp}" }
              lines << ''
            end
            next
          end

          method_name = "test_#{index.to_s.rjust(3, '0')}_#{MinitestTranslator.parameterize(test_case.description)}"
          lines << "  def #{method_name}"
          code = GeneratedCode.new(test_case)
          lines.concat(code.result_lines)
          test_case.expectations.each do |expectation|
            lines.concat(assertion_lines(code, expectation))
          end
          lines << '  end'
          lines << ''
        end

        if testrun.teardown && !testrun.teardown.empty?
          lines << '  def teardown'
          testrun.teardown.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << '  end'
        end

        lines << 'end'
        lines.join("\n")
      end

      private

      # The Minitest assertions for one tryouts expectation, with the same
      # pass/fail as direct mode (see GeneratedCode)
      def assertion_lines(code, expectation)
        expr = code.expression(expectation)
        case expectation.type
        when :regular then ["    assert_equal(#{expr}, #{code.result})"]
        when :true then ["    assert_same(true, #{expr})"] # rubocop:disable Lint/BooleanSymbol
        when :false then ["    assert_same(false, #{expr})"] # rubocop:disable Lint/BooleanSymbol
        when :boolean then ["    assert_includes([true, false], #{expr})"]
        when :result_type then ["    assert_kind_of(#{expr}, #{code.result})"]
        when :regex_match then ["    assert_match(#{expr}, #{code.result}.to_s)"]
        when :non_nil
          # Not nil and, where the code may have rescued one, no error
          [*("    assert_nil #{code.error}" if code.rescues?), "    refute_nil #{code.result}"]
        when :exception
          # Only once the code has raised is the expression evaluated, as in
          # direct mode, and its value decides: a Module is what the error
          # must be a kind of, anything else must be truthy. The value is a
          # lambda parameter, so a local of the test's keeps its own.
          ["    refute_nil #{code.error}",
           '    ->(expected) do',
           '      if expected.is_a?(Module)',
           "        assert_kind_of expected, #{code.error}",
           '      else',
           '        assert expected',
           '      end',
           "    end.call(#{expr})"]
        else
          ["    flunk(#{code.untranslated_message(expectation, 'Minitest').inspect})"]
        end
      end
    end
  end
end
