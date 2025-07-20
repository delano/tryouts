# lib/tryouts/translators/rspec_translator.rb

class Tryouts
  module Translators
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
              result = instance_eval(test_case.code, testrun.source_file) unless test_case.code.strip.empty?

              test_case.expectations.each do |expectation|
                expected_value = instance_eval(expectation, testrun.source_file)
                expect(result).to eq(expected_value)
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
          unless test_case.code.strip.empty?
            lines << '    result = begin'
            test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
            lines << '    end'
          end

          test_case.expectations.each do |expectation|
            lines << "    expect(result).to eq(#{expectation})"
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
