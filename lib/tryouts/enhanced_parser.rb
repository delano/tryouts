# Enhanced parser using Prism's inhouse comment extraction capabilities
# Drop-in replacement for PrismParser that eliminates HEREDOC parsing issues

require 'prism'
require_relative 'test_case'

class Tryouts
  # Enhanced parser that replaces manual line-by-line parsing with inhouse Prism APIs
  # while maintaining full compatibility with the original parser's logic structure
  class EnhancedParser
    def initialize(source_path)
      @source_path  = source_path
      @source       = File.read(source_path)
      @lines        = @source.lines.map(&:chomp)
      @prism_result = Prism.parse(@source)
    end

    def parse
      return handle_syntax_errors if @prism_result.failure?

      # Use inhouse comment extraction instead of line-by-line regex parsing
      # This automatically excludes HEREDOC content!
      tokens           = tokenize_content_with_inhouse_extraction
      test_boundaries  = find_test_case_boundaries(tokens)
      tokens           = classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
      test_blocks      = group_into_test_blocks(tokens)
      process_test_blocks(test_blocks)
    end

    private

    # Inhouse comment extraction - replaces the manual regex parsing
    def tokenize_content_with_inhouse_extraction
      tokens = []

      # Get all comments using inhouse Prism extraction
      comments = Prism.parse_comments(@source)
      comment_by_line = {}
      comments.each { |comment| comment_by_line[comment.location.start_line] = comment }

      # Process each line, using inhouse comment extraction where available
      @lines.each_with_index do |line, index|
        line_number = index + 1

        if comment_by_line[line_number]
          comment = comment_by_line[line_number]
          comment_content = comment.slice.strip

          # Check if this is an inline comment (comment doesn't start at beginning of line)
          if comment.location.start_column > 0
            # Inline comment - treat the whole line as code to preserve formatting
            token = { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
          else
            # Standalone comment line - process as comment
            token = classify_comment_inhousely(comment_content, line_number)
          end
        else
          # Handle non-comment lines (blank lines and code)
          token = case line
                  when /^\s*$/
                    { type: :blank, line: index }
                  else
                    { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
                  end
        end

        tokens << token
      end

      tokens
    end

    # Inhouse comment classification - replaces complex regex patterns
    def classify_comment_inhousely(content, line_number)
      case content
      when /^##\s*(.*)$/
        { type: :description, content: $1.strip, line: line_number - 1 }
      when /^#\s*TEST\s*\d*:\s*(.*)$/
        { type: :description, content: $1.strip, line: line_number - 1 }
      when /^#\s*=!>\s*(.*)$/
        { type: :exception_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=<>\s*(.*)$/
        { type: :intentional_failure_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*==>\s*(.*)$/
        { type: :true_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when %r{^#\s*=/=>\s*(.*)$}
        { type: :false_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=\|>\s*(.*)$/
        { type: :boolean_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=:>\s*(.*)$/
        { type: :result_type_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=~>\s*(.*)$/
        { type: :regex_match_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=%>\s*(.*)$/
        { type: :performance_time_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^#\s*=(\d+)>\s*(.*)$/
        { type: :output_expectation, content: $2.strip, pipe: $1.to_i, line: line_number - 1, ast: parse_expectation($2.strip) }
      when /^#\s*=>\s*(.*)$/
        { type: :expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      when /^##\s*=>\s*(.*)$/
        { type: :comment, content: '=>' + $1.strip, line: line_number - 1 }
      when /^#\s*(.*)$/
        { type: :potential_description, content: $1.strip, line: line_number - 1 }
      else
        { type: :comment, content: content.sub(/^#\s*/, ''), line: line_number - 1 }
      end
    end

    # Copy the rest of the methods from PrismParser to maintain identical behavior

    def find_test_case_boundaries(tokens)
      boundaries = []

      tokens.each_with_index do |token, index|
        if token[:type] == :description
          start_line = token[:line]
          end_line   = find_test_case_end(tokens, index)
          boundaries << { start: start_line, end: end_line } if end_line
        end
      end

      boundaries
    end

    def find_test_case_end(tokens, start_index)
      last_expectation_line = nil

      (start_index + 1).upto(tokens.length - 1) do |i|
        token = tokens[i]
        break if token[:type] == :description

        if is_expectation_type?(token[:type])
          last_expectation_line = token[:line]
        end
      end

      last_expectation_line
    end

    def classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
      tokens.map.with_index do |token, index|
        if token[:type] == :potential_description
          line_num         = token[:line]
          within_test_case = test_boundaries.any? do |boundary|
            line_num >= boundary[:start] && line_num <= boundary[:end]
          end

          if within_test_case
            token.merge(type: :comment)
          else
            content = token[:content].strip

            looks_like_test_description = content.match?(/test|example|demonstrate|show|should|when|given/i) &&
                                          content.length > 10

            prev_token      = index > 0 ? tokens[index - 1] : nil
            has_code_before = prev_token && prev_token[:type] == :code

            if has_code_before || !looks_like_test_description
              token.merge(type: :comment)
            else
              following_tokens = tokens[(index + 1)..]
              meaningful_following = following_tokens.reject { |t| [:blank, :comment].include?(t[:type]) }
              test_window     = meaningful_following.first(5)
              has_code        = test_window.any? { |t| t[:type] == :code }
              has_expectation = test_window.any? { |t| is_expectation_type?(t[:type]) }

              if has_code && has_expectation && looks_like_test_description
                token.merge(type: :description)
              else
                token.merge(type: :comment)
              end
            end
          end
        else
          token
        end
      end
    end

    def is_expectation_type?(type)
      [
        :expectation, :exception_expectation, :intentional_failure_expectation,
        :true_expectation, :false_expectation, :boolean_expectation,
        :result_type_expectation, :regex_match_expectation,
        :performance_time_expectation, :output_expectation
      ].include?(type)
    end

    def group_into_test_blocks(tokens)
      blocks        = []
      current_block = new_test_block

      tokens.each do |token|
        case [current_block, token]
        in [_, { type: :description, content: String => desc, line: Integer => line_num }]
          if !current_block[:description].empty? && current_block[:code].empty? && current_block[:expectations].empty?
            current_block[:description] = [current_block[:description], desc].join(' ').strip
          else
            blocks << current_block if block_has_content?(current_block)
            current_block = new_test_block.merge(description: desc, start_line: line_num)
          end

        in [{ expectations: [], start_line: nil }, { type: :code, content: String => code, line: Integer => line_num }]
          current_block[:code] << token
          current_block[:start_line] = line_num

        in [{ expectations: [] }, { type: :code, content: String => code }]
          current_block[:code] << token

        in [{ expectations: Array => exps }, { type: :code }] if !exps.empty?
          blocks << current_block
          current_block = new_test_block.merge(code: [token], start_line: token[:line])

        in [_, { type: :expectation }]
          current_block[:expectations] << token

        in [_, { type: :exception_expectation }]
          current_block[:expectations] << token

        in [_, { type: :intentional_failure_expectation }]
          current_block[:expectations] << token

        in [_, { type: :true_expectation }]
          current_block[:expectations] << token

        in [_, { type: :false_expectation }]
          current_block[:expectations] << token

        in [_, { type: :boolean_expectation }]
          current_block[:expectations] << token

        in [_, { type: :result_type_expectation }]
          current_block[:expectations] << token

        in [_, { type: :regex_match_expectation }]
          current_block[:expectations] << token

        in [_, { type: :performance_time_expectation }]
          current_block[:expectations] << token

        in [_, { type: :output_expectation }]
          current_block[:expectations] << token

        in [_, { type: :comment | :blank }]
          add_context_to_block(current_block, token)
        end
      end

      blocks << current_block if block_has_content?(current_block)
      classify_blocks(blocks)
    end

    def process_test_blocks(classified_blocks)
      setup_blocks    = classified_blocks.filter { |block| block[:type] == :setup }
      test_blocks     = classified_blocks.filter { |block| block[:type] == :test }
      teardown_blocks = classified_blocks.filter { |block| block[:type] == :teardown }

      Testrun.new(
        setup: build_setup(setup_blocks),
        test_cases: test_blocks.map { |block| build_test_case(block) },
        teardown: build_teardown(teardown_blocks),
        source_file: @source_path,
        metadata: { parsed_at: Time.now, parser: :enhanced },
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

      valid_blocks = blocks.filter { |block| block[:start_line] && block[:end_line] }
      return 0..0 if valid_blocks.empty?

      line_ranges = valid_blocks.map { |block| block[:start_line]..block[:end_line] }
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
        start_line: nil,
        end_line: nil,
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
        block[:code] << token
      in [false, { type: :comment | :blank }]
        block[:comments] << token
      end
    end

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
                       :preamble
                     end

        block.merge(type: block_type, end_line: calculate_end_line(block))
      end
    end

    def calculate_end_line(block)
      content_tokens = [*block[:code], *block[:expectations]]
      return block[:start_line] if content_tokens.empty?

      content_tokens.map { |token| token[:line] }.max || block[:start_line]
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
        source_lines = @lines[start_line..end_line]
        first_expectation_line = exp_tokens.empty? ? start_line : exp_tokens.first[:line]

        TestCase.new(
          description: desc,
          code: extract_code_content(code_tokens),
          expectations: exp_tokens.map do |token|
            type = case token[:type]
                   when :exception_expectation then :exception
                   when :intentional_failure_expectation then :intentional_failure
                   when :true_expectation then :true # rubocop:disable Lint/BooleanSymbol
                   when :false_expectation then :false # rubocop:disable Lint/BooleanSymbol
                   when :boolean_expectation then :boolean
                   when :result_type_expectation then :result_type
                   when :regex_match_expectation then :regex_match
                   when :performance_time_expectation then :performance_time
                   when :output_expectation then :output
                   else :regular
                   end

            if token[:type] == :output_expectation
              OutputExpectation.new(content: token[:content], type: type, pipe: token[:pipe])
            else
              Expectation.new(content: token[:content], type: type)
            end
          end,
          line_range: start_line..end_line,
          path: @source_path,
          source_lines: source_lines,
          first_expectation_line: first_expectation_line,
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
