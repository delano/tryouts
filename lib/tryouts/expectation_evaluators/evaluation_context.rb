# lib/tryouts/expectation_evaluators/evaluation_context.rb
#
# frozen_string_literal: true

class Tryouts
  module ExpectationEvaluators
    # Raised when an expectation expression is not valid Ruby. SyntaxError is a
    # ScriptError, so without this an expectation typo would escape every
    # evaluator's `rescue StandardError` and abort the file.
    class ExpressionSyntaxError < StandardError; end

    # Everything an expectation can refer to, for one execution of one test.
    #
    # Each expectation is compiled into a lambda inside the test's own binding:
    #
    #   ->(result, _, error, elapsed_ms) { <expression> }
    #
    # so the expression sees the test's local variables, instance variables and
    # constants exactly as the test code left them. `result`, `_`, `error` and
    # `elapsed_ms` are lambda parameters: they belong to this test alone and
    # cannot leak into the next one.
    class EvaluationContext
      attr_reader :result, :error, :elapsed_ms, :stdout, :stderr

      # @param binding [Binding] the binding the test code ran in
      # @param path [String] source file, for backtraces
      # @param result [Object] value of the test's last statement, or the
      #   exception it raised
      # @param error [Exception, nil] exception raised by the test code
      # @param elapsed_ns [Integer, nil] test code run time
      # @param stdout [String, nil] captured stdout (only for #=1> tests)
      # @param stderr [String, nil] captured stderr (only for #=2> tests)
      def initialize(binding:, path:, result: nil, error: nil, elapsed_ns: nil, stdout: nil, stderr: nil)
        @binding    = binding
        @path       = path
        @result     = result
        @error      = error
        @elapsed_ms = elapsed_ns && (elapsed_ns / 1_000_000.0).round(2)
        @stdout     = stdout
        @stderr     = stderr
      end

      # @param expression [String] Ruby source after the expectation arrow
      # @param line [Integer] 1-based line of the expectation comment
      def evaluate(expression, line)
        # The expression gets its own line so a trailing `# comment` in it
        # cannot swallow the closing brace. Starting the eval one line early
        # puts the expression on the expectation's real line.
        check = @binding.eval("->(result, _, error, elapsed_ms) {\n#{expression}\n}", @path, line - 1)
        check.call(@result, @result, @error, @elapsed_ms)
      rescue SyntaxError => ex
        raise ExpressionSyntaxError, ex.message.lines.reject { |l| l.include?('->(result, _, error, elapsed_ms)') }.join.strip
      end
    end
  end
end
