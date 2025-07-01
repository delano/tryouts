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
        line_type, content = parse_line(line)

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

      Testrun.new(
        setup: build_setup(setup_lines),
        test_cases: test_cases,
        teardown: build_teardown(teardown_lines),
        source_file: @source_path,
        metadata: { parsed_at: Time.now, parser: :prism },
      )
    end

    def parse_line(line)
      case line
      in /^##\s*(.*)/ if ::Regexp.last_match(1)
        [:description, ::Regexp.last_match(1).strip]
      in /^#\s*TEST\s+\d+:\s*(.*)/ if ::Regexp.last_match(1) # rubocop:disable Lint/DuplicateBranch
        [:description, ::Regexp.last_match(1).strip]
      in /^#=>\s*(.*)/ if ::Regexp.last_match(1)
        [:expectation, ::Regexp.last_match(1).strip]
      in /^#[^#=>](.*)/ if ::Regexp.last_match(1)
        [:comment, ::Regexp.last_match(1).strip]
      in /^\s*$/
        [:blank, nil]
      else
        [:code, line]
      end
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

      line_range = test_data[:line_start]..(@lines.size - 1)

      PrismTestCase.new(
        description: test_data[:description].join(' ').strip,
        code: test_data[:code].join("\n"),
        expectations: test_data[:expectations],
        line_range: line_range,
        path: @source_path,
      )
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
