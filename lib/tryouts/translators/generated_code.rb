# lib/tryouts/translators/generated_code.rb
#
# frozen_string_literal: true

require 'prism'
require_relative '../expectation_evaluators/registry'

class Tryouts
  module Translators
    # What --generate-rspec and --generate-minitest write for one test case,
    # other than the assertions themselves.
    #
    # The test code runs once and its value is `result`. A test that may
    # raise (a #=!>, #=:> or #=~> expectation, as in direct mode) rescues the
    # exception into `error`, and `result` is the exception too. The other
    # names direct mode gives an expectation, `_`, `error` when nothing is
    # rescued, and `elapsed_ms`, are defined when an expectation reads them.
    #
    # An expectation the generators have no assertion for still gets one
    # that fails, saying what it was, so the generated file never passes a
    # test direct mode fails.
    module GeneratedCode
      INDENT = '    '

      # Operators shown in the failure for an expectation that is not
      # translated
      OPERATORS = { intentional_failure: '#=<>', performance_time: '#=%>' }.freeze

      # What an expectation can read besides `result`
      VARIABLES = [:_, :error, :elapsed_ms].freeze

      # Statements that have a value only as the last thing a lambda does
      JUMPS = [Prism::NextNode, Prism::BreakNode, Prism::RedoNode, Prism::ReturnNode].freeze

      # @return [Array<String>] the lines that run the code into `result`
      def self.result_lines(test_case)
        code = test_case.code.lines.map { |line| "#{INDENT}  #{line.chomp}" }
        return ["#{INDENT}result = nil"] if code.empty?

        reads   = variables(test_case)
        rescued = rescued_errors(test_case)
        lines   = []
        lines << "#{INDENT}error = nil" if reads.include?(:error) && rescued.nil?
        lines << "#{INDENT}started = Process.clock_gettime(Process::CLOCK_MONOTONIC)" if reads.include?(:elapsed_ms)
        lines << "#{INDENT}result = begin"
        lines.concat(code)
        case rescued
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
        lines << "#{INDENT}elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(2)" if reads.include?(:elapsed_ms)
        lines << "#{INDENT}_ = result" if reads.include?(:_)
        lines
      end

      # The expectation's source as an expression of its own, on its own
      # line inside parentheses, as direct mode evaluates it: a trailing
      # `# comment` or a `{ ... }` hash in it stays what it is. One that
      # jumps (`next 1`, `break`) has a value only inside a lambda, which
      # direct mode gives every expectation, so it is called inside one.
      def self.expression(expectation)
        inner = "(\n#{INDENT}  #{expectation.content}\n#{INDENT})"
        jumps?(expectation) ? "-> { #{inner} }.call" : inner
      end

      # True when the test's code may have rescued an exception into `error`
      def self.rescues?(test_case)
        !rescued_errors(test_case).nil?
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

      # The names in VARIABLES that the test's expectations read
      def self.variables(test_case)
        test_case.expectations.flat_map do |expectation|
          nodes(parse(expectation)).grep(Prism::LocalVariableReadNode).map(&:name)
        end & VARIABLES
      end

      def self.jumps?(expectation)
        nodes(parse(expectation)).any? { |node| JUMPS.include?(node.class) }
      end

      def self.rescued_errors(test_case)
        if test_case.exception_expectations?
          :program
        elsif test_case.expectations.any? { |exp| exp.result_type? || exp.regex_match? }
          :standard
        end
      end

      # The expectation's source parsed as direct mode compiles it, with the
      # expectation variables in scope
      def self.parse(expectation)
        Prism.parse("(\n#{expectation.content}\n)", scopes: [[:result, *VARIABLES]]).value
      end

      # The node and every node under it
      def self.nodes(node)
        [node, *node.compact_child_nodes.flat_map { |child| nodes(child) }]
      end
      private_class_method :rescued_errors, :parse, :nodes
    end
  end
end
