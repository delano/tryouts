# lib/tryouts/expectation_evaluators/malformed.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # A comment shaped like an expectation with an operator that does not
    # exist, such as `#=INVALID> 2`, `#=!!> x` or `#===> x`, or one written
    # behind a description marker (`##=> 2`). It always fails, so a typo
    # surfaces as a failing test instead of a test that silently vanishes.
    # The parser also reports it as a malformed_expectation warning. Nothing
    # after the arrow is evaluated.
    class Malformed < Base
      OPERATORS = '#=>, #==>, #=/=>, #=|>, #=!>, #=:>, #=~>, #=%>, #=*>, #=<>, #=1>, #=2>'

      def self.handles?(expectation_type)
        expectation_type == :malformed
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
        if @expectation.content.start_with?('##')
          "an expectation with a single '#' ('#=>' asserts, '# #=>' is a comment)"
        else
          "a valid expectation operator (#{OPERATORS})"
        end
      end
    end
  end
end
