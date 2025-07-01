# frozen_string_literal: true

class Tryouts
  module Translators
    class RSpecTranslator
      def initialize
        require 'rspec/core'
      rescue LoadError
        raise "RSpec gem is required for RSpec translation"
      end

      def translate(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')

        RSpec.describe "Tryouts: #{file_basename}" do
          # Setup before all tests
          if testrun.setup && !testrun.setup.empty?
            before(:all) do
              instance_eval(testrun.setup.code)
            end
          end

          # Generate test cases
          testrun.test_cases.each_with_index do |test_case, index|
            next if test_case.empty? || !test_case.has_expectations?

            it test_case.description do
              result = instance_eval(test_case.code) if test_case.code.strip.any?

              test_case.expectations.each do |expectation|
                expected_value = instance_eval(expectation)
                expect(result).to eq(expected_value)
              end
            end
          end

          # Teardown after all tests
          if testrun.teardown && !testrun.teardown.empty?
            after(:all) do
              instance_eval(testrun.teardown.code)
            end
          end
        end
      end

      def generate_code(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        lines = []

        lines << "# Generated RSpec test from #{testrun.source_file}"
        lines << "# Generated at: #{Time.now}"
        lines << ""
        lines << "RSpec.describe '#{file_basename}' do"

        if testrun.setup && !testrun.setup.empty?
          lines << "  before(:all) do"
          testrun.setup.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << "  end"
          lines << ""
        end

        testrun.test_cases.each_with_index do |test_case, index|
          next if test_case.empty? || !test_case.has_expectations?

          lines << "  it '#{test_case.description}' do"
          if test_case.code.strip.any?
            lines << "    result = begin"
            test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
            lines << "    end"
          end

          test_case.expectations.each do |expectation|
            lines << "    expect(result).to eq(#{expectation})"
          end
          lines << "  end"
          lines << ""
        end

        if testrun.teardown && !testrun.teardown.empty?
          lines << "  after(:all) do"
          testrun.teardown.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << "  end"
        end

        lines << "end"
        lines.join("\n")
      end
    end
  end
end
