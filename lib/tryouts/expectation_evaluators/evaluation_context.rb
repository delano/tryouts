# lib/tryouts/expectation_evaluators/evaluation_context.rb
#
# frozen_string_literal: true

require 'prism'

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
      PARAMETERS = [:result, :_, :error, :elapsed_ms].freeze

      attr_reader :result, :error, :elapsed_ms, :stdout, :stderr

      # @param binding [Binding] the binding the test code ran in
      # @param path [String] source file, for backtraces
      # @param magic_comments [Array<String>] the file's magic comments
      # @param result [Object] value of the test's last statement, or the
      #   exception it raised
      # @param error [Exception, nil] exception raised by the test code
      # @param elapsed_ns [Integer, nil] test code run time
      # @param stdout [String, nil] captured stdout (only for #=1> tests)
      # @param stderr [String, nil] captured stderr (only for #=2> tests)
      def initialize(binding:, path:, magic_comments: [], result: nil, error: nil, elapsed_ns: nil, stdout: nil, stderr: nil)
        @binding        = binding
        @path           = path
        @magic_comments = magic_comments
        @result         = result
        @error          = error
        @elapsed_ms     = elapsed_ns && (elapsed_ns / 1_000_000.0).round(2)
        @stdout         = stdout
        @stderr         = stderr
      end

      # @param expression [String] Ruby source after the expectation arrow
      # @param line [Integer] 1-based line of the expectation comment
      def evaluate(expression, line)
        check_syntax(expression, line)

        # The expression gets its own line so a trailing `# comment` in it
        # cannot swallow the closing brace. The file's magic comments and the
        # lambda header go on the lines above it, so the expression sits on
        # the expectation's real line.
        source = [*@magic_comments, '->(result, _, error, elapsed_ms) {', expression, '}'].join("\n")
        check  = @binding.eval(source, @path, line - 1 - @magic_comments.size)
        check.call(@result, @result, @error, @elapsed_ms)
      rescue SyntaxError
        # Ruby's own message would point at the lambda wrapped around the
        # expression, which the user never wrote.
        raise ExpressionSyntaxError, syntax_error_message(expression, line)
      end

      private

      # Parse the expression on its own, with the test's locals in scope, so
      # a syntax error is described in terms of what the user wrote and at the
      # expectation's own line. `__END__` parses, but would cut the wrapped
      # source short.
      def check_syntax(expression, line)
        parsed = Prism.parse(expression, scopes: [@binding.local_variables + PARAMETERS])
        return unless parsed.failure? || parsed.data_loc

        reason = parsed.errors.first&.message || '__END__ cannot appear in an expectation'
        raise ExpressionSyntaxError, syntax_error_message(expression, line, reason)
      end

      def syntax_error_message(expression, line, reason = nil)
        ["#{@path}:#{line}: syntax error in expectation `#{expression.strip}`", reason].compact.join(': ')
      end
    end
  end
end
