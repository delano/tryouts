# lib/tryouts/parsers/statement_parser.rb
#
# frozen_string_literal: true

require 'prism'

require_relative '../test_case'
require_relative '../parser_warning'

class Tryouts
  # Parses a tryouts file by anchoring every comment to a top-level statement.
  #
  # A tryouts file is a Ruby script. Prism already knows where each top-level
  # statement starts and ends and where every real comment is (comments inside
  # heredocs and string literals are not comments). This parser only decides,
  # for each comment, which statement it belongs to:
  #
  #   - a comment on the same line as the end of a statement is that
  #     statement's *trailing* comment (`1 + 1 #=> 2`)
  #   - a comment between two statements sits in the *gap* after the first
  #   - a comment inside a statement's span is part of that statement's body
  #
  # Expectation comments in a statement's trailing slot or in the gap after it
  # are assertions about that statement's value; that statement is a test's
  # *subject*. A test case is the run of statements that ends at its subject
  # and starts after the nearest `##` description (or, without one, right
  # after the previous subject). Statements before the first test are setup,
  # statements after the last subject are teardown, and statements between a
  # subject and the next test's description are an interlude (OrphanBlock)
  # that runs in source order.
  #
  # @example
  #   testrun = Tryouts::StatementParser.new('try/basic_try.rb').parse
  #   testrun.test_cases.first.expectations.first.line  # 0-based source line
  class StatementParser
    # Operator text between `#=` and `>` mapped to the expectation type.
    # `#=>` has an empty operator.
    OPERATORS = {
      '' => :regular,
      '=' => :true, # rubocop:disable Lint/BooleanSymbol
      '/=' => :false, # rubocop:disable Lint/BooleanSymbol
      '|' => :boolean,
      '!' => :exception,
      '<' => :intentional_failure,
      '*' => :non_nil,
      ':' => :result_type,
      '~' => :regex_match,
      '%' => :performance_time,
    }.freeze

    EXPECTATION_PATTERN = %r{\A#(?<space>\s*)=(?<op>/=|\d+|[=|!<*:~%]|)>\s?(?<body>.*)\z}m
    DESCRIPTION_PATTERN = /\A##+(?!\s*=\S*>)\s*(?<text>.*)\z/m
    VACUOUS_BOOLEAN     = /\A(true|false|nil)\s*(#.*)?\z/

    attr_reader :source_path, :warnings

    # One entry per top-level statement, with its full extent. A heredoc body
    # lies after the statement's own location (which ends at `<<~X`), so the
    # extent is widened to the heredoc terminator.
    Statement = Struct.new(:node, :start_offset, :end_offset, :start_line, :end_line, :trailing, :gap) do
      # Trailing expectations come first: they are on the statement's own line.
      def expectations
        (trailing + gap).select { |c| c[:kind] == :expectation }
      end

      def subject?
        trailing.any? { |c| c[:kind] == :expectation } || gap.any? { |c| c[:kind] == :expectation }
      end
    end

    def initialize(source_path, options = {})
      @source_path  = source_path
      @source       = File.read(source_path, mode: 'r:BOM|UTF-8')
      @lines        = @source.lines.map(&:chomp)
      @prism_result = Prism.parse(@source, filepath: source_path)
      @parsed_at    = Time.now
      @options      = options
      @warnings     = []
    end

    # @return [Tryouts::Testrun]
    # @raise [Tryouts::TryoutSyntaxError] on a Ruby syntax error, or on a strict
    #   mode violation
    def parse
      raise_syntax_error if @prism_result.failure?

      @statements = build_statements
      attach_comments

      testrun = assemble
      validate_strict_mode
      testrun
    end

    private

    def build_statements
      body = @prism_result.value.statements.body
      body.map do |node|
        loc        = node.location
        end_offset = extent_end_offset(node)
        Statement.new(
          node, loc.start_offset, end_offset,
          loc.start_line, line_at(end_offset - 1),
          [], []
        )
      end
    end

    def extent_end_offset(node)
      end_offset = node.location.end_offset
      return end_offset unless @source.byteslice(node.location.start_offset, node.location.length).include?('<<')

      stack          = [node]
      while (current = stack.pop)
        if current.respond_to?(:heredoc?) && current.heredoc? && current.closing_loc
          end_offset = [end_offset, current.closing_loc.end_offset].max
        end
        stack.concat(current.compact_child_nodes)
      end
      end_offset
    end

    def line_at(byte_offset)
      @prism_result.source.line(byte_offset)
    end

    # Walk comments and statements together (both are in source order) and file
    # every comment under the statement it belongs to. Comments before the first
    # statement go to @leading_gap.
    def attach_comments
      @leading_gap = []
      index        = 0

      @prism_result.comments.each do |comment|
        loc    = comment.location
        offset = loc.start_offset
        line   = loc.start_line

        index += 1 while index < @statements.size && @statements[index].end_offset <= offset

        current = @statements[index]
        if current && current.start_offset <= offset
          # Inside a statement's extent. The one exception is a comment after
          # the statement's own code on its last line, ahead of a heredoc body.
          node_loc = current.node.location
          if offset >= node_loc.end_offset && line == node_loc.end_line
            current.trailing << classify(comment, trailing: true)
          else
            warn_about_nested_expectation(comment)
          end
          next
        end

        previous = index.positive? ? @statements[index - 1] : nil
        if previous && line == previous.end_line
          previous.trailing << classify(comment, trailing: true)
        elsif previous
          previous.gap << classify(comment, trailing: false)
        else
          @leading_gap << classify(comment, trailing: false)
        end
      end
    end

    def classify(comment, trailing:)
      line = comment.location.start_line - 1 # 0-based, like every line in Testrun
      return { kind: :comment, line: line } if comment.is_a?(Prism::EmbDocComment)

      text = comment.slice.strip

      if (match = EXPECTATION_PATTERN.match(text))
        return expectation_token(match, text, line)
      end

      if !trailing && (match = DESCRIPTION_PATTERN.match(text))
        return { kind: :description, text: match[:text].strip, line: line }
      end

      case malformed_expectation(text, trailing: trailing)
      when :typo
        # Almost certainly a mistyped operator. Keep it as an expectation that
        # fails, so the test stays visible instead of silently vanishing.
        add_malformed_warning(text, line)
        { kind: :expectation, type: :malformed, content: text, pipe: nil, line: line, spaced: false }
      when :suspicious
        add_malformed_warning(text, line)
        { kind: :comment, line: line }
      else
        { kind: :comment, line: line }
      end
    end

    def add_malformed_warning(text, line)
      @warnings << ParserWarning.malformed_expectation(
        line_number: line + 1,
        syntax: malformed_syntax(text),
        context: text,
      )
    end

    def expectation_token(match, text, line)
      op   = match[:op]
      body = match[:body].strip
      type = op.match?(/\A\d+\z/) ? :output : OPERATORS.fetch(op)

      if [:true, :false, :boolean].include?(type) && body.match?(VACUOUS_BOOLEAN) # rubocop:disable Lint/BooleanSymbol
        @warnings << ParserWarning.vacuous_expectation(line_number: line + 1, context: text)
      elsif type == :non_nil && !body.empty?
        @warnings << ParserWarning.ignored_expectation_text(line_number: line + 1, context: text)
      end

      {
        kind: :expectation,
        type: type,
        content: body,
        pipe: (op.to_i if type == :output),
        line: line,
        spaced: !match[:space].empty?,
      }
    end

    def warn_about_nested_expectation(comment)
      text = comment.slice.strip
      return unless text.start_with?('#=') && EXPECTATION_PATTERN.match?(text)

      @warnings << ParserWarning.nested_expectation(
        line_number: comment.location.start_line,
        context: text,
      )
    end

    # Comments that look like an attempt at an expectation but are not one.
    # A `#=...>` shape is a typo of a real operator (:typo). A comment opening
    # with `>` or `<` might be one (:suspicious); after code on the same line
    # that is ordinary prose (`x # > 3 is fine`), so it is not flagged there.
    def malformed_expectation(text, trailing:)
      return nil if text.start_with?('##')
      return :typo if text.match?(/\A#\s*=\s+>/)       # "# = >"
      return :typo if text.match?(/\A#\s*===+>/)       # "#===>"
      return :typo if text.match?(%r{\A#\s*=[^=:!~%*|/>\s<\d][^>\s]*>}) # "#=X>"
      return nil if trailing

      :suspicious if text.match?(/\A#\s*>[^=]/) || text.match?(/\A#\s*<[^=]/)
    end

    def malformed_syntax(text)
      text.sub(/\A#\s*/, '')[/\A\S+/] || 'unknown'
    end

    # Turn the annotated statement list into Setup, test cases (with interludes
    # in between) and Teardown.
    def assemble
      subjects    = @statements.each_index.select { |i| @statements[i].subject? }
      test_cases  = []
      setup_range = nil
      cursor      = 0

      warn_about_unanchored_expectations

      subjects.each do |subject_index|
        gap_index, description = description_for(cursor, subject_index)
        first_index            = gap_index ? gap_index + 1 : cursor

        if first_index > cursor
          interlude = cursor...first_index
          if test_cases.empty?
            setup_range = interlude
          else
            test_cases << build_section(OrphanBlock, interlude)
          end
        end

        test_cases << build_test_case(first_index..subject_index, description)
        cursor = subject_index + 1
      end

      setup_range    = 0...@statements.size if subjects.empty?
      teardown_range = subjects.empty? ? nil : cursor...@statements.size

      Testrun.new(
        setup: build_section(Setup, setup_range),
        test_cases: test_cases,
        teardown: build_section(Teardown, teardown_range),
        source_file: @source_path,
        metadata: { parsed_at: @parsed_at, parser: :statement },
        warnings: @warnings,
      )
    end

    # The nearest `##` description between the previous subject and this one.
    # Gap g sits after statement g, so the test begins at statement g + 1. A
    # gap that also holds the previous subject's expectations only offers the
    # descriptions written after them. Consecutive `##` lines join into one
    # description.
    #
    # @return [Array(Integer, Hash), nil] gap index (-1 for the file's leading
    #   gap) and description info
    def description_for(cursor, subject_index)
      (subject_index - 1).downto(cursor - 1) do |gap_index|
        gap         = gap_index.negative? ? @leading_gap : @statements[gap_index].gap
        last_expect = gap.rindex { |c| c[:kind] == :expectation } || -1
        lines       = gap[(last_expect + 1)..].select { |c| c[:kind] == :description }
        next if lines.empty?

        text = lines.map { |c| c[:text] }.reject(&:empty?).join(' ')
        return [gap_index, { text: text, line: lines.first[:line] }]
      end
      nil
    end

    def build_test_case(range, description)
      first   = @statements[range.first]
      subject = @statements[range.last]
      tokens  = subject.expectations

      start_line = description ? description[:line] : first.start_line - 1
      end_line   = [tokens.last[:line], subject.end_line - 1].max

      collect_unnamed_test_warning(range, tokens) unless description && !description[:text].empty?

      TestCase.new(
        description: description ? description[:text] : '',
        code: code_for(range),
        expectations: tokens.map { |t| build_expectation(t) },
        line_range: start_line..end_line,
        path: @source_path,
        source_lines: @lines[start_line..end_line],
        first_expectation_line: tokens.first[:line],
        first_code_line: first.start_line - 1,
      )
    end

    def build_expectation(token)
      if token[:type] == :output
        OutputExpectation.new(content: token[:content], type: :output, pipe: token[:pipe], line: token[:line])
      else
        Expectation.new(content: token[:content], type: token[:type], line: token[:line])
      end
    end

    # Setup, Teardown and OrphanBlock share one shape.
    def build_section(klass, range)
      if range.nil? || range.none?
        return klass.new(code: '', line_range: 0..0, path: @source_path, first_code_line: nil)
      end

      first = @statements[range.first]
      last  = @statements[range.max]
      klass.new(
        code: code_for(range),
        line_range: (first.start_line - 1)..(last.end_line - 1),
        path: @source_path,
        first_code_line: first.start_line - 1,
      )
    end

    # The exact source of a statement run, comments between its statements
    # included. Evaluated with first_code_line, every statement in it reports
    # its true line in a backtrace.
    def code_for(range)
      first = @statements[range.first]
      last  = @statements[range.max]
      @source.byteslice(first.start_offset, last.end_offset - first.start_offset)
    end

    # Expectations that come before any statement have nothing to assert on.
    def warn_about_unanchored_expectations
      @leading_gap.each do |c|
        next unless c[:kind] == :expectation

        @warnings << ParserWarning.expectation_without_subject(
          line_number: c[:line] + 1,
          context: @lines[c[:line]].to_s.strip,
        )
      end
    end

    def collect_unnamed_test_warning(range, tokens)
      first   = @statements[range.first]
      subject = @statements[range.last]
      @warnings << ParserWarning.unnamed_test(
        line_number: first.start_line,
        context: @lines[first.start_line - 1].to_s.strip,
        expectation_line: tokens.first[:line] + 1,
        subject_line: subject.start_line,
        statement_count: range.size,
        spaced: tokens.first[:spaced],
        swallows_prologue: range.first.zero? && range.size > 1,
      )
    end

    def raise_syntax_error
      error = @prism_result.errors.first
      line  = error.location.start_line
      raise TryoutSyntaxError.new(
        error.message,
        line_number: line,
        context: @lines[line - 1] || '',
        source_file: @source_path,
      )
    end

    def validate_strict_mode
      return unless @options[:strict]

      first = @warnings.find { |w| w.type == :unnamed_test }
      return unless first

      raise TryoutSyntaxError.new(
        "Strict mode: #{first.message} at line #{first.line_number}. #{first.suggestion}",
        line_number: first.line_number,
        context: first.context,
        source_file: @source_path,
      )
    end
  end
end
