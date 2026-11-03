# lib/tryouts/expectation_evaluators/malformed.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # An expectation that cannot be evaluated. It always fails, so a mistake
    # surfaces as a failing test instead of a test that silently vanishes,
    # and the parser also reports it as a warning. Nothing after the arrow is
    # evaluated. Two kinds:
    #
    # - :malformed is a comment shaped like an expectation with an operator
    #   that does not exist, such as `#=INVALID> 2`, `#=!!> x`, `#= = > x`
    #   or `#<=> x`, or one written behind a description marker (`##=> 2`).
    # - :detached is an expectation with no statement above it in its own
    #   test: before the first statement, or directly under a `##` line.
    class Malformed < Base
      OPERATORS = '#=>, #==>, #=/=>, #=|>, #=!>, #=:>, #=~>, #=%>, #=*>, #=<>, #=1>, #=2>'

      def self.handles?(expectation_type)
        [:malformed, :detached].include?(expectation_type)
      end

      def evaluate(actual_result = nil)
        build_result(
          passed: false,
          actual: actual_result,
          expected: "#{wanted}, got: #{@expectation.content}",
        )
      end

      private

      def wanted
        if @expectation.type == :detached
          "a statement above line #{expectation_line} to assert on (there is none in this test)"
        elsif @expectation.content.start_with?('##')
          "an expectation with a single '#' ('#=>' asserts, '# #=>' is a comment)"
        else
          "a valid expectation operator (#{OPERATORS})"
        end
      end
    end
  end
end
