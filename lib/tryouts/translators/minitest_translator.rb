# lib/tryouts/translators/minitest_translator.rb

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
              instance_eval(testrun.setup.code)
            end
          end

          # Generate test methods
          testrun.test_cases.each_with_index do |test_case, index|
            next if test_case.empty? || !test_case.expectations?

            method_name = "test_#{index.to_s.rjust(3, '0')}_#{parameterize(test_case.description)}"
            define_method(method_name) do
              if test_case.exception_expectations?
                # Handle exception expectations
                assert_raises(StandardError) do
                  instance_eval(test_case.code) unless test_case.code.strip.empty?
                end

                test_case.exception_expectations.each do |expectation|
                  result = instance_eval(expectation.content)
                  assert result, "Exception expectation failed: #{expectation.content}"
                end
              else
                # Handle regular expectations
                result = instance_eval(test_case.code) unless test_case.code.strip.empty?

                test_case.regular_expectations.each do |expectation|
                  expected_value = instance_eval(expectation.content)
                  assert_equal expected_value, result
                end
              end
            end
          end

          # Teardown method
          if testrun.teardown && !testrun.teardown.empty?
            define_method(:teardown) do
              instance_eval(testrun.teardown.code)
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
        lines         = []

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
          next if test_case.empty? || !test_case.expectations?

          method_name = "test_#{index.to_s.rjust(3, '0')}_#{parameterize(test_case.description)}"
          lines << "  def #{method_name}"

          if test_case.exception_expectations?
            # Handle exception expectations
            lines << '    error = assert_raises(StandardError) do'
            unless test_case.code.strip.empty?
              test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
            end
            lines << '    end'

            test_case.exception_expectations.each do |expectation|
              lines << "    assert #{expectation}, \"Exception expectation failed: #{expectation}\""
            end
          else
            # Handle regular expectations
            unless test_case.code.strip.empty?
              lines << '    result = begin'
              test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
              lines << '    end'
            end

            test_case.expectations.each do |expectation|
              lines << "    assert_equal #{expectation}, result"
            end
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

      # Simple string parameterization for method names
      def parameterize(string)
        string.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
      end
    end
  end
end
