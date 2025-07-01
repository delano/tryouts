# frozen_string_literal: true

class Tryouts
  module Translators
    class MinitestTranslator
      def initialize
        require 'minitest/test'
      rescue LoadError
        raise "Minitest gem is required for Minitest translation"
      end

      def translate(testrun)
        file_basename = File.basename(testrun.source_file, '.rb')
        class_name = "Test#{file_basename.gsub(/[^A-Za-z0-9]/, '')}"

        test_class = Class.new(Minitest::Test) do
          # Setup method
          if testrun.setup && !testrun.setup.empty?
            define_method(:setup) do
              instance_eval(testrun.setup.code)
            end
          end

          # Generate test methods
          testrun.test_cases.each_with_index do |test_case, index|
            next if test_case.empty? || !test_case.has_expectations?

            method_name = "test_#{index.to_s.rjust(3, '0')}_#{test_case.description.parameterize}"
            define_method(method_name) do
              result = instance_eval(test_case.code) if test_case.code.strip.any?

              test_case.expectations.each do |expectation|
                expected_value = instance_eval(expectation)
                assert_equal expected_value, result
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
        class_name = "Test#{file_basename.gsub(/[^A-Za-z0-9]/, '')}"
        lines = []

        lines << "# Generated Minitest from #{testrun.source_file}"
        lines << "# Generated at: #{Time.now}"
        lines << ""
        lines << "require 'minitest/test'"
        lines << ""
        lines << "class #{class_name} < Minitest::Test"

        if testrun.setup && !testrun.setup.empty?
          lines << "  def setup"
          testrun.setup.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << "  end"
          lines << ""
        end

        testrun.test_cases.each_with_index do |test_case, index|
          next if test_case.empty? || !test_case.has_expectations?

          method_name = "test_#{index.to_s.rjust(3, '0')}_#{test_case.description.parameterize}"
          lines << "  def #{method_name}"
          if test_case.code.strip.any?
            lines << "    result = begin"
            test_case.code.lines.each { |line| lines << "      #{line.chomp}" }
            lines << "    end"
          end

          test_case.expectations.each do |expectation|
            lines << "    assert_equal #{expectation}, result"
          end
          lines << "  end"
          lines << ""
        end

        if testrun.teardown && !testrun.teardown.empty?
          lines << "  def teardown"
          testrun.teardown.code.lines.each { |line| lines << "    #{line.chomp}" }
          lines << "  end"
        end

        lines << "end"
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

# Add parameterize method to String for convenience
class String
  def parameterize
    downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
  end unless method_defined?(:parameterize)
end
