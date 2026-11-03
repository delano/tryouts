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
  # An expectation with no statement above it in its own test (before the
  # first statement, or below a `##` line with no code in between) is an
  # expectation_without_subject warning and a test of its own that always
  # fails. It never attaches to the test above the description.
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

    # `#=>>` is not `#=>` with a body of `> ...`; it is a mistyped operator.
    EXPECTATION_PATTERN = %r{\A#(?<space>\s*)=(?<op>/=|\d+|[=|!<*:~%]|)>(?!>)\s?(?<body>.*)\z}m
    # What follows the `#` of anything shaped like an expectation: optional
    # spaces, `=`, an operator-like token, and `>`. The token may hold spaces
    # between operator characters and digits (`= = >`, `=2 2>`, `=1 >`) but
    # not between words, so prose such as `# = Section >` is not one. `<=`
    # or `>=` straight after the `#` is an operator written backwards
    # (`#<=>`, `#>=`).
    OPERATOR_SHAPE      = %r{(?:\s*=[^\s>]*[\s=<!|*:~%/\\\d-]*>|[<>]=\S*)}
    # One that EXPECTATION_PATTERN rejects is a mistyped operator (`#=!!>`,
    # `#=/>`, `#=1x>`, `#= = >`, `#<=>`). The match runs to the end of the
    # token (`#=>>`), so it is the whole mistyped operator.
    EXPECTATION_SHAPE   = /\A##{OPERATOR_SHAPE}\S*/
    # The same shape behind a description marker (`##=>`, `###=>`,
    # `## = >`) is an expectation with one `#` too many, never a description.
    DOUBLED_SHAPE       = /\A##+#{OPERATOR_SHAPE}\S*/
    # A `##` line with text after it. A bare `##` is a plain comment.
    DESCRIPTION_PATTERN = /\A##++\s*(?<text>\S.*)\z/m
    VACUOUS_BOOLEAN     = /\A(true|false|nil)\s*(#.*)?\z/

    attr_reader :source_path, :warnings

    # One entry per top-level statement, with its full extent. A heredoc body
    # lies after the statement's own location (which ends at `<<~X`), so the
    # extent is widened to the heredoc terminator. Statements that share a
    # heredoc's opener line are one entry (see build_statements).
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

      testrun = assemble.with(magic_comments: Testrun.magic_comments_from(@prism_result))
      validate_strict_mode
      testrun
    end

    private

    # A statement that starts inside the previous one's extent shares the
    # opener line of a heredoc (`a = <<~A; b = 1`). The two run as one unit,
    # so each runs once and the slice holds every body opened on the line.
    # The later statement is the unit's node: its value is the unit's value
    # and its end is where the trailing slot starts.
    def build_statements
      @prism_result.value.statements.body.each_with_object([]) do |node, statements|
        loc        = node.location
        end_offset = extent_end_offset(node)
        previous   = statements.last

        if previous && loc.start_offset < previous.end_offset
          previous.node       = node
          previous.end_offset = [previous.end_offset, end_offset].max
          previous.end_line   = line_at(previous.end_offset - 1)
        else
          statements << Statement.new(
            node, loc.start_offset, end_offset,
            loc.start_line, line_at(end_offset - 1),
            [], []
          )
        end
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

      # Checked before the description pattern: `##=>` is not a description.
      case malformed_expectation(text, trailing: trailing)
      when :typo, :doubled
        # Almost certainly a mistyped operator. Keep it as an expectation that
        # fails, so the test stays visible instead of silently vanishing.
        add_malformed_warning(text, line)
        return { kind: :expectation, type: :malformed, content: text, pipe: nil, line: line, spaced: false }
      when :suspicious
        add_malformed_warning(text, line)
        return { kind: :comment, line: line }
      end

      if !trailing && (match = DESCRIPTION_PATTERN.match(text))
        return { kind: :description, text: match[:text].strip, line: line }
      end

      { kind: :comment, line: line }
    end

    def add_malformed_warning(text, line)
      @warnings << if text.start_with?('##')
                     ParserWarning.doubled_hash_expectation(
                       line_number: line + 1,
                       syntax: text[DOUBLED_SHAPE],
                       context: text,
                     )
                   else
                     ParserWarning.malformed_expectation(
                       line_number: line + 1,
                       syntax: malformed_syntax(text),
                       context: text,
                     )
                   end
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
    # An OPERATOR_SHAPE is a typo of a real operator (:typo). The same shape
    # behind `##` is an expectation written with one `#` too many (:doubled);
    # it is not a description and not a way to comment an expectation out
    # (`# #=>` is). A comment opening with `>` or `<` might be one
    # (:suspicious); after code on the same line that is ordinary prose
    # (`x # > 3 is fine`), so it is not flagged there.
    def malformed_expectation(text, trailing:)
      return :doubled if text.match?(DOUBLED_SHAPE)
      return nil if text.start_with?('##')
      return :typo if text.match?(EXPECTATION_SHAPE)
      return nil if trailing

      :suspicious if text.match?(/\A#\s*>[^=]/) || text.match?(/\A#\s*<[^=]/)
    end

    # The whole operator token, spaces and closing `>` included (`=1 >`,
    # `=>>`). A :suspicious comment has no such shape; its first word stands in.
    def malformed_syntax(text)
      (text[EXPECTATION_SHAPE] || text[/\A#\s*\S*/]).sub(/\A#\s*/, '')
    end

    # Turn the annotated statement list into Setup, test cases (with interludes
    # in between) and Teardown.
    def assemble
      detached    = detach_unanchored_expectations
      subjects    = @statements.each_index.select { |i| @statements[i].subject? }
      test_cases  = []
      setup_range = nil
      cursor      = 0

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
        test_cases: (test_cases + detached).sort_by { |tc| tc.first_code_line || tc.first_expectation_line },
        teardown: build_section(Teardown, teardown_range),
        source_file: @source_path,
        metadata: { parsed_at: @parsed_at, parser: :statement },
        warnings: @warnings,
      )
    end

    # The nearest `##` description between the previous subject and this one.
    # Gap g sits after statement g, so the test begins at statement g + 1. A
    # gap that also holds the previous subject's expectations only offers the
    # descriptions written after them. Only `##` lines on adjacent lines join
    # into one description, and the last such block before the code is the
    # test's description. An earlier block, cut off by a blank line or a plain
    # comment (a section heading, a commented-out test), is a comment.
    #
    # @return [Array(Integer, Hash), nil] gap index (-1 for the file's leading
    #   gap) and description info
    def description_for(cursor, subject_index)
      (subject_index - 1).downto(cursor - 1) do |gap_index|
        gap         = gap_index.negative? ? @leading_gap : @statements[gap_index].gap
        last_expect = gap.rindex { |c| c[:kind] == :expectation } || -1
        lines       = gap[(last_expect + 1)..].select { |c| c[:kind] == :description }
        next if lines.empty?

        block = lines.slice_when { |a, b| b[:line] != a[:line] + 1 }.to_a.last
        text  = block.map { |c| c[:text] }.join(' ')
        return [gap_index, { text: text, line: block.first[:line] }]
      end
      nil
    end

    def build_test_case(range, description)
      first   = @statements[range.first]
      subject = @statements[range.last]
      tokens  = subject.expectations

      start_line = description ? description[:line] : first.start_line - 1
      end_line   = [tokens.last[:line], subject.end_line - 1].max

      collect_unnamed_test_warning(range, tokens) unless description

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

    # An expectation needs a statement above it in its own test. One that
    # comes before any statement has none, and neither has one written below
    # a `##` line with no statement in between: the description starts the
    # next test, so the statement above it belongs to another test. Either
    # way the expectation never attaches to a test it was not written for.
    # It is reported, and it becomes a test of its own that always fails,
    # named by the description above it (unnamed before the first one). The
    # description still names the test that follows too.
    #
    # @return [Array<TestCase>] the failing tests, one per description
    def detach_unanchored_expectations
      gaps = [[@leading_gap, 0]] + @statements.map { |s| [s.gap, s.gap.index { |c| c[:kind] == :description }] }
      gaps.flat_map { |gap, from| from ? detach_expectations(gap, from) : [] }
    end

    def detach_expectations(gap, from)
      groups = [] # [description lines, expectation tokens]
      gap.each_with_index do |c, i|
        next if i < from

        case c[:kind]
        when :description
          current = groups.last
          if current && current[1].empty? && current[0].last[:line] + 1 == c[:line]
            current[0] << c
          else
            groups << [[c], []]
          end
        when :expectation
          groups << [[], []] if groups.empty?
          groups.last[1] << c
          gap[i] = { kind: :detached, line: c[:line] }
        end
      end

      groups.reject { |_, tokens| tokens.empty? }.map { |lines, tokens| build_detached_test(lines, tokens) }
    end

    def build_detached_test(description_lines, tokens)
      start_line = (description_lines.first || tokens.first)[:line]
      end_line   = tokens.last[:line]

      tokens.each do |t|
        @warnings << ParserWarning.expectation_without_subject(
          line_number: t[:line] + 1,
          context: @lines[t[:line]].to_s.strip,
          description_line: description_lines.first && (description_lines.first[:line] + 1),
        )
      end

      TestCase.new(
        description: description_lines.map { |c| c[:text] }.join(' '),
        code: '',
        expectations: tokens.map { |t| Expectation.new(content: @lines[t[:line]].strip, type: :detached, line: t[:line]) },
        line_range: start_line..end_line,
        path: @source_path,
        source_lines: @lines[start_line..end_line],
        first_expectation_line: tokens.first[:line],
        first_code_line: nil,
      )
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
