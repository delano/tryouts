# Modern Ruby 3.4+ solution for the teardown bug

require 'prism'
require_relative 'test_case'

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

      tokens           = tokenize_content
      test_boundaries  = find_test_case_boundaries(tokens)
      tokens           = classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
      test_blocks      = group_into_test_blocks(tokens)
      process_test_blocks(test_blocks)
    end

    private

    # Tokenize content using pattern matching for clean line classification
    def tokenize_content
      tokens = []

      @lines.each_with_index do |line, index|
        token = case line
                in /^##\s*(.*)$/ # Test description format: ## description
                  { type: :description, content: $1.strip, line: index }
                in /^#\s*TEST\s*\d*:\s*(.*)$/  # rubocop:disable Lint/DuplicateBranch
                  { type: :description, content: $1.strip, line: index }
                in /^#\s*=!>\s*(.*)$/ # Exception expectation (updated for consistency)
                  { type: :exception_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=<>\s*(.*)$/ # Intentional failure expectation
                  { type: :intentional_failure_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*==>\s*(.*)$/ # Boolean true expectation
                  { type: :true_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in %r{^#\s*=/=>\s*(.*)$} # Boolean false expectation
                  { type: :false_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=\|>\s*(.*)$/ # Boolean (true or false) expectation
                  { type: :boolean_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=:>\s*(.*)$/ # Result type expectation
                  { type: :result_type_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=~>\s*(.*)$/ # Regex match expectation
                  { type: :regex_match_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=%>\s*(.*)$/ # Performance time expectation
                  { type: :performance_time_expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^#\s*=(\d+)>\s*(.*)$/ # Output expectation (stdout/stderr with pipe number)
                  { type: :output_expectation, content: $2.strip, pipe: $1.to_i, line: index, ast: parse_expectation($2.strip) }
                in /^#\s*=>\s*(.*)$/ # Regular expectation
                  { type: :expectation, content: $1.strip, line: index, ast: parse_expectation($1.strip) }
                in /^##\s*=>\s*(.*)$/ # Commented out expectation (should be ignored)
                  { type: :comment, content: '=>' + $1.strip, line: index }
                in /^#\s*(.*)$/ # Single hash comment - potential description
                  { type: :potential_description, content: $1.strip, line: index }
                in /^\s*$/ # Blank line
                  { type: :blank, line: index }
                else # Ruby code
                  { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
                end

        tokens << token
      end

      # Return tokens with potential_descriptions - they'll be classified later with test boundaries
      tokens
    end

    # Find actual test case boundaries by looking for ## descriptions or # TEST: patterns
    # followed by code and expectations
    def find_test_case_boundaries(tokens)
      boundaries = []

      tokens.each_with_index do |token, index|
        # Look for explicit test descriptions (## or # TEST:)
        if token[:type] == :description
          # Find the end of this test case by looking for the last expectation
          # before the next description or end of file
          start_line = token[:line]
          end_line = find_test_case_end(tokens, index)

          boundaries << { start: start_line, end: end_line } if end_line
        end
      end

      boundaries
    end

    # Find where a test case ends by looking for the last expectation
    # before the next test description or end of tokens
    def find_test_case_end(tokens, start_index)
      last_expectation_line = nil

      # Look forward from the description for expectations
      (start_index + 1).upto(tokens.length - 1) do |i|
        token = tokens[i]

        # Stop if we hit another test description
        break if token[:type] == :description

        # Track the last expectation we see
        if is_expectation_type?(token[:type])
          last_expectation_line = token[:line]
        end
      end

      last_expectation_line
    end

    # Convert potential_descriptions to descriptions or comments using test case boundaries
    def classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
      tokens.map.with_index do |token, index|
        if token[:type] == :potential_description
          # Check if this comment falls within any test case boundary
          line_num = token[:line]
          within_test_case = test_boundaries.any? { |boundary|
            line_num >= boundary[:start] && line_num <= boundary[:end]
          }

          if within_test_case
            # This comment is within a test case, treat as regular comment
            token.merge(type: :comment)
          else
            # For comments outside test boundaries, be more conservative
            # Only treat as description if it immediately precedes a test pattern AND
            # looks like a test description
            content = token[:content].strip

            # Check if this looks like a test description based on content
            looks_like_test_description = content.match?(/test|example|demonstrate|show|should|when|given/i) &&
                                        content.length > 10

            # Check if there's code immediately before this (suggesting it's mid-test)
            prev_token = index > 0 ? tokens[index - 1] : nil
            has_code_before = prev_token && prev_token[:type] == :code

            if has_code_before || !looks_like_test_description
              # Treat as regular comment
              token.merge(type: :comment)
            else
              # Look ahead for IMMEDIATE test pattern (stricter than before)
              following_tokens = tokens[(index + 1)..]

              # Skip blanks and comments to find meaningful content
              meaningful_following = following_tokens.reject { |t| [:blank, :comment].include?(t[:type]) }

              # Look for test pattern within next 5 tokens (more restrictive)
              test_window = meaningful_following.first(5)
              has_code = test_window.any? { |t| t[:type] == :code }
              has_expectation = test_window.any? { |t| is_expectation_type?(t[:type]) }

              # Only promote to description if BOTH code and expectation are found nearby
              # AND it looks like a test description
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

    # Convert potential_descriptions to descriptions or comments based on context
    def classify_potential_descriptions(tokens)
      tokens.map.with_index do |token, index|
        if token[:type] == :potential_description
          # Check if this looks like a test description based on content and context
          content = token[:content].strip

          # Skip if it's clearly just a regular comment (short, lowercase, etc.)
          # Test descriptions are typically longer and more descriptive
          looks_like_regular_comment = content.length < 20 &&
                                      content.downcase == content &&
                                      !content.match?(/test|example|demonstrate|show/i)

          # Check if there's code immediately before this (suggesting it's mid-test)
          prev_token = index > 0 ? tokens[index - 1] : nil
          has_code_before = prev_token && prev_token[:type] == :code

          if looks_like_regular_comment || has_code_before
            # Treat as regular comment
            token.merge(type: :comment)
          else
            # Look ahead for test pattern: code + at least one expectation within reasonable distance
            following_tokens = tokens[(index + 1)..]

            # Skip blanks and comments to find meaningful content
            meaningful_following = following_tokens.reject { |t| [:blank, :comment].include?(t[:type]) }

            # Look for test pattern: at least one code token followed by at least one expectation
            # within the next 10 meaningful tokens (to avoid matching setup/teardown)
            test_window = meaningful_following.first(10)
            has_code = test_window.any? { |t| t[:type] == :code }
            has_expectation = test_window.any? { |t| is_expectation_type?(t[:type]) }

            if has_code && has_expectation
              token.merge(type: :description)
            else
              token.merge(type: :comment)
            end
          end
        else
          token
        end
      end
    end

    # Check if token type represents any kind of expectation
    def is_expectation_type?(type)
      [
        :expectation, :exception_expectation, :intentional_failure_expectation,
        :true_expectation, :false_expectation, :boolean_expectation,
        :result_type_expectation, :regex_match_expectation,
        :performance_time_expectation, :output_expectation
      ].include?(type)
    end

    # Group tokens into logical test blocks using pattern matching
    def group_into_test_blocks(tokens)
      blocks        = []
      current_block = new_test_block

      tokens.each do |token|
        case [current_block, token]
        in [_, { type: :description, content: String => desc, line: Integer => line_num }]
          # Only combine descriptions if current block has a description but no code/expectations yet
          # Allow blank lines between multi-line descriptions
          if !current_block[:description].empty? && current_block[:code].empty? && current_block[:expectations].empty?
            # Multi-line description continuation
            current_block[:description] = [current_block[:description], desc].join(' ').strip
          else
            # Start new test block on description
            blocks << current_block if block_has_content?(current_block)
            current_block = new_test_block.merge(description: desc, start_line: line_num)
          end

        in [{ expectations: [], start_line: nil }, { type: :code, content: String => code, line: Integer => line_num }]
          # First code in a new block - set start_line
          current_block[:code] << token
          current_block[:start_line] = line_num

        in [{ expectations: [] }, { type: :code, content: String => code }]
          # Code before expectations - add to current block
          current_block[:code] << token

        in [{ expectations: Array => exps }, { type: :code }] if !exps.empty?
          # Code after expectations - finalize current block and start new one
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

      # Filter out blocks with nil line numbers and build valid ranges
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
                       :preamble # Default fallback
                     end

        block.merge(type: block_type, end_line: calculate_end_line(block))
      end
    end

    def calculate_end_line(block)
      # Only consider actual content (code and expectations), not blank lines/comments
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
        # Extract source lines from the original source during parsing
        source_lines = @lines[start_line..end_line]

        TestCase.new(
          description: desc,
          code: extract_code_content(code_tokens),
          expectations: exp_tokens.map { |token|
            type = case token[:type]
                   when :exception_expectation then :exception
                   when :intentional_failure_expectation then :intentional_failure
                   when :true_expectation then :true
                   when :false_expectation then :false
                   when :boolean_expectation then :boolean
                   when :result_type_expectation then :result_type
                   when :regex_match_expectation then :regex_match
                   when :performance_time_expectation then :performance_time
                   when :output_expectation then :output
                   else :regular
                   end

            # For output expectations, we need to preserve the pipe number
            if token[:type] == :output_expectation
              OutputExpectation.new(content: token[:content], type: type, pipe: token[:pipe])
            else
              Expectation.new(content: token[:content], type: type)
            end
          },
          line_range: start_line..end_line,
          path: @source_path,
          source_lines: source_lines,
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
