# lib/tryouts/translators/generated_code.rb
#
# frozen_string_literal: true

require_relative '../expectation_evaluators/registry'

class Tryouts
  module Translators
    # What --generate-rspec and --generate-minitest write for one test case,
    # other than the assertions themselves.
    #
    # The test code runs once and its value is `result`. A test that may
    # raise (a #=!>, #=:> or #=~> expectation, as in direct mode) rescues the
    # exception into `error`, and `result` is the exception too.
    #
    # An expectation the generators have no assertion for still gets one
    # that fails, saying what it was, so the generated file never passes a
    # test direct mode fails.
    module GeneratedCode
      INDENT = '    '

      # Operators shown in the failure for an expectation that is not
      # translated
      OPERATORS = { intentional_failure: '#=<>', performance_time: '#=%>' }.freeze

      # @return [Array<String>] the lines that run the code into `result`
      def self.result_lines(test_case)
        code = test_case.code.lines.map { |line| "#{INDENT}  #{line.chomp}" }
        return ["#{INDENT}result = nil"] if code.empty?

        lines  = ["#{INDENT}result = begin", *code]
        case rescued_errors(test_case)
        when :program
          # Every exception but a signal or exit, as TestBatch::ProgramError
          lines << "#{INDENT}rescue Exception => error"
          lines << "#{INDENT}  raise if error.is_a?(SignalException) || error.is_a?(SystemExit)"
          lines << "#{INDENT}  error"
        when :standard
          lines << "#{INDENT}rescue StandardError => error"
          lines << "#{INDENT}  error"
        end
        lines << "#{INDENT}end"
      end

      # The expectation's source as an expression of its own, on its own
      # line inside parentheses, as direct mode evaluates it: a trailing
      # `# comment` or a `{ ... }` hash in it stays what it is.
      def self.expression(expectation)
        "(\n#{INDENT}  #{expectation.content}\n#{INDENT})"
      end

      # True when the expectation's source is a constant such as
      # ArgumentError or Net::ReadTimeout, which #=!> checks with is_a?
      def self.constant?(expectation)
        expectation.content.match?(/\A(::)?[A-Z]\w*(::[A-Z]\w*)*\z/)
      end

      # Why an expectation without an assertion of its own fails
      def self.untranslated_message(test_case, expectation, framework)
        line = expectation.line ? "line #{expectation.line + 1}: " : ''
        case expectation.type
        when :malformed, :detached
          outcome = ExpectationEvaluators::Registry.evaluator_for(expectation, test_case, nil).evaluate
          "#{line}expected #{outcome[:expected]}"
        else
          operator = OPERATORS.fetch(expectation.type) { "#=#{expectation.pipe}>" if expectation.output? }
          "#{line}#{operator} #{expectation.content} is not translated to #{framework}; " \
            "run the tryouts file with --#{framework.downcase} to check it"
        end
      end

      def self.rescued_errors(test_case)
        if test_case.exception_expectations?
          :program
        elsif test_case.expectations.any? { |exp| exp.result_type? || exp.regex_match? }
          :standard
        end
      end
      private_class_method :rescued_errors
    end
  end
end
