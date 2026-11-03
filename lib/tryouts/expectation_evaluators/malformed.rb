# lib/tryouts/expectation_evaluators/malformed.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # A comment shaped like an expectation with an operator that does not
    # exist, such as `#=INVALID> 2` or `#===> x`. It always fails, so a typo
    # surfaces as a failing test instead of a test that silently vanishes.
    # The parser also reports it as a malformed_expectation warning. Nothing
    # after the arrow is evaluated.
    class Malformed < Base
      def self.handles?(expectation_type)
        expectation_type == :malformed
      end

      def evaluate(actual_result = nil)
        build_result(
          passed: false,
          actual: actual_result,
          expected: "a valid expectation operator (#=>, #==>, #=/=>, #=|>, #=!>, #=:>, #=~>, #=%>, #=*>, #=<>, #=1>, #=2>), got: #{@expectation.content}",
        )
      end
    end
  end
end
