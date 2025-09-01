require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    class Diagnostic < Base
      def self.handles?(expectation_type)
        expectation_type == :diagnostic
      end

      def evaluate(actual_result)
        # Evaluate the diagnostic expression in the test context
        diagnostic_result = @context.instance_eval(@expectation.content)

        # Diagnostic expectations never fail - they're for information only
        build_result(
          passed: true,  # Always pass - diagnostics don't affect test outcome
          actual: diagnostic_result,
          expected: nil,  # No expected result for diagnostics
          expectation: @expectation.content
        ).merge(diagnostic: true)  # Add diagnostic flag
      rescue => e
        # Even if diagnostic evaluation fails, don't fail the test
        build_result(
          passed: true,
          actual: e,
          expected: nil,
          expectation: @expectation.content,
          error: e.message
        ).merge(diagnostic: true)
      end
    end
  end
end
