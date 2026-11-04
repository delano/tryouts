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
    # rescued, and `elapsed_ms`, are defined when an expectation uses them.
    #
    # Those names, and `started` for the timing, belong to the generated
    # code. Where the test's code or its expectations use one for something
    # of their own, the generated code adds an underscore to its name
    # (`error_`) until the name is free, so a local the test assigns can
    # never pass for the exception it did not raise. An expectation sees
    # `result`, `_`, `error` and `elapsed_ms` as direct mode gives them, and
    # one that assigns to them, or reads one held under another name, is
    # called in a lambda that takes them as parameters, as direct mode calls
    # every expectation.
    #
    # An expectation the generators have no assertion for still gets one
    # that fails, saying what it was, so the generated file never passes a
    # test direct mode fails.
    class GeneratedCode
      INDENT = '    '

      # Operators shown in the failure for an expectation that is not
      # translated
      OPERATORS = { intentional_failure: '#=<>', performance_time: '#=%>' }.freeze

      # What an expectation sees, in the order direct mode passes them
      PARAMETERS = [:result, :_, :error, :elapsed_ms].freeze

      # Statements that have a value only as the last thing a lambda does
      JUMPS = [Prism::NextNode, Prism::BreakNode, Prism::RedoNode, Prism::ReturnNode].freeze

      # Assignments to a local variable
      WRITES = [
        Prism::LocalVariableWriteNode, Prism::LocalVariableOperatorWriteNode, Prism::LocalVariableOrWriteNode,
        Prism::LocalVariableAndWriteNode, Prism::LocalVariableTargetNode
      ].freeze

      # Uses of a local variable
      LOCALS = [Prism::LocalVariableReadNode, *WRITES].freeze

      def initialize(test_case)
        @test_case = test_case
        @nodes     = {}.compare_by_identity
        @names     = own_names
      end

      # The names the generated code holds the test's value and its error under
      def result = @names[:result]
      def error = @names[:error]

      # @return [Array<String>] the lines that run the code into `result`
      def result_lines
        code = @test_case.code.lines.map { |line| "#{INDENT}  #{line.chomp}" }
        return ["#{INDENT}#{result} = nil"] if code.empty?

        used    = used_parameters
        rescued = rescued_errors
        started = @names[:started]
        lines   = []
        lines << "#{INDENT}#{error} = nil" if used.include?(:error) && rescued.nil?
        lines << "#{INDENT}#{started} = Process.clock_gettime(Process::CLOCK_MONOTONIC)" if used.include?(:elapsed_ms)
        lines << "#{INDENT}#{result} = begin"
        lines.concat(code)
        case rescued
        when :program
          # Every exception but a signal or exit, as TestBatch::ProgramError
          lines << "#{INDENT}rescue Exception => #{error}"
          lines << "#{INDENT}  raise if #{error}.is_a?(SignalException) || #{error}.is_a?(SystemExit)"
          lines << "#{INDENT}  #{error}"
        when :standard
          lines << "#{INDENT}rescue StandardError => #{error}"
          lines << "#{INDENT}  #{error}"
        end
        lines << "#{INDENT}end"
        if used.include?(:elapsed_ms)
          lines << "#{INDENT}#{@names[:elapsed_ms]} = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - #{started}) * 1000).round(2)"
        end
        lines << "#{INDENT}#{@names[:_]} = #{result}" if used.include?(:_)
        lines
      end

      # The expectation's source as an expression of its own, on its own
      # line inside parentheses, as direct mode evaluates it: a trailing
      # `# comment` or a `{ ... }` hash in it stays what it is. One that
      # jumps (`next 1`, `break`) has a value only inside a lambda, so it is
      # called inside one; so is one that assigns to the names it sees, or
      # reads one the generated code holds under another name, with those
      # names as the lambda's parameters.
      def expression(expectation)
        inner      = "(\n#{INDENT}  #{expectation.content}\n#{INDENT})"
        nodes      = nodes_of(expectation)
        parameters = PARAMETERS & nodes.filter_map { |node| node.name if LOCALS.include?(node.class) }
        assigned   = nodes.any? { |node| WRITES.include?(node.class) && PARAMETERS.include?(node.name) }
        renamed    = parameters.any? { |name| @names[name] != name.to_s }
        jumps      = nodes.any? { |node| JUMPS.include?(node.class) }
        return inner unless jumps || assigned || renamed
        return "-> { #{inner} }.call" if parameters.empty?

        "->(#{parameters.join(', ')}) { #{inner} }.call(#{parameters.map { |name| @names[name] }.join(', ')})"
      end

      # True when the test's code may have rescued an exception into `error`
      def rescues?
        !rescued_errors.nil?
      end

      # Why an expectation without an assertion of its own fails
      def untranslated_message(expectation, framework)
        line = expectation.line ? "line #{expectation.line + 1}: " : ''
        case expectation.type
        when :malformed, :detached
          outcome = ExpectationEvaluators::Registry.evaluator_for(expectation, @test_case, nil).evaluate
          "#{line}expected #{outcome[:expected]}"
        else
          operator = OPERATORS.fetch(expectation.type) { "#=#{expectation.pipe}>" if expectation.output? }
          "#{line}#{operator} #{expectation.content} is not translated to #{framework}; " \
            "run the tryouts file with --#{framework.downcase} to check it"
        end
      end

      private

      # The names in PARAMETERS that the test's expectations use
      def used_parameters
        @test_case.expectations.flat_map do |expectation|
          nodes_of(expectation).filter_map { |node| node.name if LOCALS.include?(node.class) }
        end & PARAMETERS
      end

      def rescued_errors
        if @test_case.exception_expectations?
          :program
        elsif @test_case.expectations.any? { |exp| exp.result_type? || exp.regex_match? }
          :standard
        end
      end

      # The name for each of PARAMETERS and for `started`: its own, or with
      # underscores added until the test's code does not use it and its
      # expectations do not use it for anything but what direct mode gives
      # them.
      def own_names
        taken = identifiers(nodes(Prism.parse(@test_case.code).value)) |
                (@test_case.expectations.flat_map { |exp| identifiers(nodes_of(exp)) } - PARAMETERS)
        [*PARAMETERS, :started].to_h do |variable|
          name  = variable.to_s
          name += '_' while taken.include?(name.to_sym)
          [variable, name]
        end
      end

      # The local variables and the methods called without a receiver: the
      # names a local of the generated code would take over
      def identifiers(nodes)
        nodes.filter_map do |node|
          node.name if LOCALS.include?(node.class) || (node.is_a?(Prism::CallNode) && node.receiver.nil?)
        end
      end

      # Every node of the expectation's source, parsed as direct mode
      # compiles it, with the names it sees in scope
      def nodes_of(expectation)
        @nodes[expectation] ||= nodes(Prism.parse("(\n#{expectation.content}\n)", scopes: [PARAMETERS]).value)
      end

      # The node and every node under it
      def nodes(node)
        [node, *node.compact_child_nodes.flat_map { |child| nodes(child) }]
      end
    end
  end
end
