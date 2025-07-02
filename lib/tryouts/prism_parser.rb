# lib/tryouts/prism_parser.rb

require 'prism'
require_relative 'data_structures'

class Tryouts
  class PrismParser
    def initialize(source_path)
      @source_path = source_path
      @source      = File.read(source_path)
      @lines       = @source.lines.map(&:chomp)
      @result      = Prism.parse(@source)
    end

    def parse
      return handle_syntax_errors if @result.failure?

      parse_tryouts_structure
    end

    private

    def parse_tryouts_structure
      state          = :setup
      current_test   = nil
      setup_lines    = []
      test_cases     = []
      teardown_lines = []

      @lines.each_with_index do |line, index|
        line_type, content = parse_line(line, index)

        case [state, line_type]
        in [:setup, :description]
          state        = :test
          current_test = init_test_case(content, index)
        in [:test, :description]
          test_cases << build_test_case(current_test) if current_test
          current_test = init_test_case(content, index)
        in [:test, :code]
          current_test[:code] << line if current_test
        in [:test, :expectation]
          current_test[:expectations] << content if current_test
        in [:setup, :code]
          setup_lines << line
        in [:test, :blank | :comment]
          add_to_current_context(line, state, current_test, setup_lines)
        else
          handle_unknown_line(line, state, index)
        end
      end

      test_cases << build_test_case(current_test) if current_test

      # Detect teardown: lines after last test case
      teardown_lines = detect_teardown_lines(test_cases)

      Testrun.new(
        setup: build_setup(setup_lines),
        test_cases: test_cases,
        teardown: build_teardown(teardown_lines),
        source_file: @source_path,
        metadata: { parsed_at: Time.now, parser: :prism },
      )
    end

    def parse_line(line, line_index = nil)
      case line
      in /^##\s*(.*)/ if ::Regexp.last_match(1)
        [:description, ::Regexp.last_match(1).strip]
      in /^##?\s*TEST\s+\d+:\s*(.*)/ if ::Regexp.last_match(1) # rubocop:disable Lint/DuplicateBranch
        [:description, ::Regexp.last_match(1).strip]
      in /^#\s*=>\s*(.*)/ if ::Regexp.last_match(1)
        [:expectation, ::Regexp.last_match(1).strip]
      in /^#\s+(.*)/ if ::Regexp.last_match(1) && !::Regexp.last_match(1).strip.empty? && line_index && is_test_description?(line_index)
        [:description, ::Regexp.last_match(1).strip]
      in /^#[^#=>](.*)/ if ::Regexp.last_match(1)
        [:comment, ::Regexp.last_match(1).strip]
      in /^\s*$/
        [:blank, nil]
      else
        [:code, line]
      end
    end

    def is_test_description?(line_index)
      # Look ahead to see if this comment is followed by code (not just more comments/expectations)
      return false unless line_index

      next_lines = @lines[(line_index + 1)..-1]
      return false if next_lines.nil? || next_lines.empty?

      # Find the next non-blank, non-comment line
      next_lines.each do |next_line|
        case next_line
        when /^\s*$/ # blank line
          next
        when /^#[^>]/ # comment (not expectation)
          next
        when /^#\s*=>/ # expectation
          return false # This comment is followed by expectations, not a test description
        else # code line
          return true # This comment is followed by code, so it's a test description
        end
      end
      
      false
    end

    def init_test_case(description, line_index)
      {
        description: [description],
        code: [],
        expectations: [],
        line_start: line_index,
      }
    end

    def build_test_case(test_data)
      return nil unless test_data

      # Calculate proper end line for this test case
      start_line = test_data[:line_start]
      end_line = find_test_end_line_from_data(test_data, start_line)
      line_range = start_line..end_line

      PrismTestCase.new(
        description: test_data[:description].join(' ').strip,
        code: test_data[:code].join("\n"),
        expectations: test_data[:expectations],
        line_range: line_range,
        path: @source_path,
      )
    end

    def find_test_end_line_from_data(test_data, start_line)
      # Find next test description line
      next_test_line = @lines[(start_line + 1)..-1].find_index do |line|
        line_type, _ = parse_line(line)
        line_type == :description
      end

      if next_test_line
        start_line + next_test_line  # Line before next test
      else
        @lines.size - 1  # End of file
      end
    end

    def build_setup(lines)
      return Setup.new(code: '', line_range: 0..0, path: @source_path) if lines.empty?

      Setup.new(
        code: lines.join("\n"),
        line_range: 0..(lines.size - 1),
        path: @source_path,
      )
    end

    def build_teardown(lines)
      return Teardown.new(code: '', line_range: 0..0, path: @source_path) if lines.empty?

      start_line = @lines.size - lines.size
      Teardown.new(
        code: lines.join("\n"),
        line_range: start_line..(@lines.size - 1),
        path: @source_path,
      )
    end

    def add_to_current_context(line, state, current_test, setup_lines)
      case state
      when :setup
        setup_lines << line unless line.strip.empty?
      when :test
        current_test[:code] << line if current_test
      end
    end

    def handle_unknown_line(line, state, index)
      # For now, treat unknown lines as code
    end

    def detect_teardown_lines(test_cases)
      return [] if test_cases.empty?

      # Look for explicit teardown marker comment
      teardown_start = @lines.find_index do |line|
        line.match?(/^#.*teardown/i)
      end

      if teardown_start
        # Everything after teardown marker
        @lines[(teardown_start + 1)..-1].reject(&:empty?)
      else
        # Fallback: use last test case end
        last_test_end_line = test_cases.map(&:line_range).map(&:last).max || 0
        return [] if last_test_end_line >= @lines.size - 1
        @lines[(last_test_end_line + 1)..-1]
      end
    end

    def find_test_case_end_line(test_case)
      # Simple approach: find last non-blank line before next test or end of file
      test_start = test_case.line_range.first

      # Look for next test case description
      next_test_line = @lines[(test_start + 1)..-1].find_index do |line|
        line_type, _ = parse_line(line)
        line_type == :description
      end

      if next_test_line
        actual_next_line = test_start + 1 + next_test_line
        actual_next_line - 1
      else
        @lines.size - 1
      end
    end

    def handle_syntax_errors
      errors = @result.errors.map do |error|
        TryoutSyntaxError.new(
          error.message,
          line_number: error.location.start_line,
          context: @lines[error.location.start_line - 1] || '',
          source_file: @source_path,
        )
      end

      raise errors.first if errors.any?
    end
  end
end
