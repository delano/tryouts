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

    # The expected value of an expectation that raised while it was being
    # evaluated (a syntax error, an undefined name). A distinct type, so an
    # ordinary expected String can never be mistaken for one.
    EvaluationError = Data.define(:message) do
      def to_s = message
      def inspect = "EXPECTED: #{message}"
    end

    # Everything an expectation can refer to, for one execution of one test.
    #
    # Each expectation is compiled into a lambda inside the test's own binding:
    #
    #   ->(result, _, error, elapsed_ms) { (
    #   <expression>
    #   ) }
    #
    # so the expression sees the test's local variables, instance variables and
    # constants exactly as the test code left them. `result`, `_`, `error` and
    # `elapsed_ms` are lambda parameters: they belong to this test alone and
    # cannot leak into the next one. The expression gets its own line, so a
    # trailing `# comment` in it cannot swallow the closing brace, and sits in
    # parentheses, so a stray `}` in it is a syntax error rather than the end
    # of the lambda.
    class EvaluationContext
      HEADER = '->(result, _, error, elapsed_ms) { ('
      FOOTER = ') }'

      # Prism describes syntax errors with the running Ruby's grammar where it
      # knows that version, and with its latest grammar otherwise.
      PRISM_OPTIONS = begin
        Prism.parse('', version: RUBY_VERSION)
        { version: RUBY_VERSION }.freeze
      rescue ArgumentError
        {}.freeze
      end

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
        compile(expression, line).call(@result, @result, @error, @elapsed_ms)
      end

      private

      # The file's magic comments and the lambda header go on the lines above
      # the expression, so it sits on the expectation's real line. Ruby is
      # the judge of what compiles; Prism only explains a SyntaxError, since
      # Ruby's own message would point at the wrapper the user never wrote.
      def compile(expression, line)
        source = [*@magic_comments, HEADER, expression, FOOTER].join("\n")
        @binding.eval(source, @path, line - 1 - @magic_comments.size)
      rescue SyntaxError
        reason = syntax_error_reason(expression)
        raise ExpressionSyntaxError, ["#{@path}:#{line}: syntax error in expectation `#{expression.strip}`", reason].compact.join(': ')
      end

      # The first error Prism reports on the expression's own line (line 2 of
      # the wrapped source). Failing that, an error at the closing line that
      # is about the expression, with the wrapper's `)` dropped from it.
      # Messages about recovering from the wrapper's braces are left out.
      def syntax_error_reason(expression)
        parsed = Prism.parse([HEADER, expression, FOOTER].join("\n"), scopes: [@binding.local_variables], **PRISM_OPTIONS)
        return '__END__ cannot appear in an expectation' if parsed.data_loc

        errors = parsed.errors.reject { |e| e.message.match?(/assuming it is closing|ignoring it/) }
        errors.find { |e| e.location.start_line == 2 }&.message ||
          errors.filter_map { |e| e.message[/\Aunexpected '\)'; (.+)/, 1] if e.location.start_line == 3 }.first
      end
    end
  end
end
