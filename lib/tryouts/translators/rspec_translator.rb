# lib/tryouts/translators/rspec_translator.rb
#
# frozen_string_literal: true

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
              instance_eval(testrun.setup.code, testrun.source_file)
            end
          end

          # Generate test cases
          testrun.test_cases.each_with_index do |test_case, _index|
            next if test_case.empty? || !test_case.expectations?

            it test_case.description do
              if test_case.exception_expectations?
                # Handle exception expectations
                error = nil
                expect do
                  instance_eval(test_case.code, testrun.source_file) unless test_case.code.strip.empty?
                end.to raise_error do |caught_error|
                  error = caught_error
                end

                test_case.exception_expectations.each do |expectation|
                  expected_value = instance_eval(expectation.content, testrun.source_file)
                  expect(expected_value).to be_truthy
                end
              else
                # Handle regular expectations
                result = instance_eval(test_case.code, testrun.source_file) unless test_case.code.strip.empty?

                test_case.regular_expectations.each do |expectation|
                  expected_value = instance_eval(expectation.content, testrun.source_file)
                  expect(result).to eq(expected_value)
                end
              end
            end
          end

          # Teardown after all tests
          if testrun.teardown && !testrun.teardown.empty?
            after(:all) do
              instance_eval(testrun.teardown.code, testrun.source_file)
            end
          end
        end
      end

      def generate_code(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        lines         = []

        lines << ''
        lines << "RSpec.describe '#{file_basename}' do"

        if testrun.setup && !testrun.setup.empty?
          lines << '  before(:all) do'
          testrun.setup.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << '  end'
          lines << ''
        end

        testrun.test_cases.each_with_index do |test_case, _index|
          next if test_case.empty? || !test_case.expectations?

          lines << "  it '#{test_case.description}' do"

          if test_case.exception_expectations?
            # Handle exception expectations
            lines << '    error = nil'
            lines << '    expect {'
            unless test_case.code.strip.empty?
              test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
            end
            lines << '    }.to raise_error do |caught_error|'
            lines << '      error = caught_error'
            lines << '    end'

            test_case.exception_expectations.each do |expectation|
              lines << "    expect(#{expectation.content}).to be_truthy"
            end
          else
            # Handle regular expectations
            unless test_case.code.strip.empty?
              lines << '    result = begin'
              test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
              lines << '    end'
            end

            test_case.regular_expectations.each do |expectation|
              lines << "    expect(result).to eq(#{expectation.content})"
            end
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
    end
  end
end
