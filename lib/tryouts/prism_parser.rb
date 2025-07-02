# Modern Ruby 3.4+ solution for the teardown bug

require 'prism'
require_relative 'data_structures'

class Tryouts
  # Fixed PrismParser with pattern matching for robust token filtering
  class PrismParser
    def initialize(source_path)
      @source_path  = source_path
      @source       = File.read(source_path)
      @lines        = @source.lines.map(&:chomp)
      @prism_result = Prism.parse(@source)
    end

    def parse
      return handle_syntax_errors if @prism_result.failure?

      tokens      = tokenize_content
      test_blocks = group_into_test_blocks(tokens)
      process_test_blocks(test_blocks)
    end

    private

    # Tokenize content using pattern matching for clean line classification
    def tokenize_content
      tokens = []

      @lines.each_with_index do |line, index|
        token = case line
                in /^##\s*(.*)$/ # Test description
                  { type: :description, content: $1.strip, line: index }
                in /^#\s*=>\s*(.*)$/ # Expectation
                  { type: :expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*(.*)$/ # Comment
                  { type: :comment, content: $1.strip, line: index }
                in /^\s*$/ # Blank line
                  { type: :blank, line: index }
                else # Ruby code
                  { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
                end

        tokens << token
      end

      tokens
    end

    # Group tokens into logical test blocks using pattern matching
    def group_into_test_blocks(tokens)
      blocks        = []
      current_block = new_test_block

      tokens.each do |token|
        case [current_block, token]
        in [_, { type: :description, content: String => desc, line: Integer => line_num }]
          # Start new test block on description
          blocks << current_block if block_has_content?(current_block)
          current_block = new_test_block.merge(description: desc, start_line: line_num)

        in [{ expectations: [] }, { type: :code, content: String => code }]
          # Code before expectations - add to current block
          current_block[:code] << token

        in [{ expectations: Array => exps }, { type: :code }] if !exps.empty?
          # Code after expectations - finalize current block and start new one
          blocks << current_block
          current_block = new_test_block.merge(code: [token])

        in [_, { type: :expectation }]
          current_block[:expectations] << token

        in [_, { type: :comment | :blank }]
          # Add context to appropriate section
          add_context_to_block(current_block, token)
        end
      end

      blocks << current_block if block_has_content?(current_block)
      classify_blocks(blocks)
    end

    # Process classified test blocks into domain objects
    def process_test_blocks(classified_blocks)
      setup_blocks    = classified_blocks.filter { |block| block[:type] == :setup }
      test_blocks     = classified_blocks.filter { |block| block[:type] == :test }
      teardown_blocks = classified_blocks.filter { |block| block[:type] == :teardown }

      Testrun.new(
        setup: build_setup(setup_blocks),
        test_cases: test_blocks.map { |block| build_test_case(block) },
        teardown: build_teardown(teardown_blocks),
        source_file: @source_path,
        metadata: { parsed_at: Time.now, parser: :prism_v2_fixed },
      )
    end

    def build_setup(setup_blocks)
      return Setup.new(code: '', line_range: 0..0, path: @source_path) if setup_blocks.empty?

      Setup.new(
        code: extract_pure_code_from_blocks(setup_blocks),
        line_range: calculate_block_range(setup_blocks),
        path: @source_path,
      )
    end

    def build_teardown(teardown_blocks)
      return Teardown.new(code: '', line_range: 0..0, path: @source_path) if teardown_blocks.empty?

      Teardown.new(
        code: extract_pure_code_from_blocks(teardown_blocks),
        line_range: calculate_block_range(teardown_blocks),
        path: @source_path,
      )
    end

    # Modern Ruby 3.4+ pattern matching for robust code extraction
    # This filters out comments added by add_context_to_block explicitly
    def extract_pure_code_from_blocks(blocks)
      blocks
        .flat_map { |block| block[:code] }
        .filter_map do |token|
          case token
          in { type: :code, content: String => content }
            content
          else
            nil
          end
        end
        .join("\n")
    end

    def calculate_block_range(blocks)
      return 0..0 if blocks.empty?

      line_ranges = blocks.map { |block| block[:start_line]..block[:end_line] }
      line_ranges.first.first..line_ranges.last.last
    end

    def extract_code_content(code_tokens)
      code_tokens
        .filter_map do |token|
          case token
          in { type: :code, content: String => content }
            content
          else
            nil
          end
        end
        .join("\n")
    end

    def parse_ruby_line(line)
      return nil if line.strip.empty?

      result = Prism.parse(line.strip)
      case result
      in { errors: [] => errors, value: { body: { body: [ast] } } }
        ast
      in { errors: Array => errors } if errors.any?
        { type: :parse_error, errors: errors, raw: line }
      else
        nil
      end
    end

    def parse_expectation(expr)
      parse_ruby_line(expr)
    end

    def new_test_block
      {
        description: '',
        code: [],
        expectations: [],
        comments: [],
        start_line: 0,
        end_line: 0,
      }
    end

    def block_has_content?(block)
      case block
      in { description: String => desc, code: Array => code, expectations: Array => exps }
        !desc.empty? || !code.empty? || !exps.empty?
      else
        false
      end
    end

    def add_context_to_block(block, token)
      case [block[:expectations].empty?, token]
      in [true, { type: :comment | :blank }]
        # Comments before expectations go with code
        block[:code] << token
      in [false, { type: :comment | :blank }]
        # Comments after expectations are test context
        block[:comments] << token
      end
    end

    # Classify blocks as setup, test, or teardown based on content
    def classify_blocks(blocks)
      blocks.map.with_index do |block, index|
        block_type = case block
                     in { expectations: [] } if index == 0
                       :setup
                     in { expectations: [] } if index == blocks.size - 1
                       :teardown
                     in { expectations: Array => exps } if !exps.empty?
                       :test
                     else
                       :setup # Default fallback
                     end

        block.merge(type: block_type, end_line: calculate_end_line(block))
      end
    end

    def calculate_end_line(block)
      last_tokens = [*block[:code], *block[:expectations], *block[:comments]]
      return block[:start_line] if last_tokens.empty?

      last_tokens.map { |token| token[:line] }.max || block[:start_line]
    end

    def build_test_case(block)
      case block
      in {
        type: :test,
        description: String => desc,
        code: Array => code_tokens,
        expectations: Array => exp_tokens,
        start_line: Integer => start_line,
        end_line: Integer => end_line
      }
        PrismTestCase.new(
          description: desc,
          code: extract_code_content(code_tokens),
          expectations: exp_tokens.map { |token| token[:content] },
          line_range: start_line..end_line,
          path: @source_path,
        )
      else
        raise "Invalid test block structure: #{block}"
      end
    end

    def handle_syntax_errors
      errors = @prism_result.errors.map do |error|
        line_context = @lines[error.location.start_line - 1] || ''

        TryoutSyntaxError.new(
          error.message,
          line_number: error.location.start_line,
          context: line_context,
          source_file: @source_path,
        )
      end

      raise errors.first if errors.any?
    end
  end
end
