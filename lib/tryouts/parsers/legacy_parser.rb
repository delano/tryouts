# lib/tryouts/parsers/legacy_parser.rb

require_relative '../test_case'
require_relative 'base_parser'

class Tryouts
  # Fixed LegacyParser with pattern matching for robust token filtering
  class LegacyParser < Tryouts::Parsers::BaseParser

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
                in /^#\s*=\*>\s*(.*)$/ # Non-nil expectation
                  { type: :non_nil_expectation, content: $1.strip, line: index }
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
                in /^#\s*=([^>=:!~%*|\/\s]+)>\s*(.*)$/ # Malformed expectation - invalid characters between = and >
                  syntax = $1
                  content_part = $2.strip
                  add_warning(ParserWarning.malformed_expectation(
                    line_number: index + 1,
                    syntax: syntax,
                    context: line.strip
                  ))
                  { type: :malformed_expectation, syntax: syntax, content: content_part, line: index }
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
          prev_token      = index > 0 ? tokens[index - 1] : nil
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
            test_window     = meaningful_following.first(10)
            has_code        = test_window.any? { |t| t[:type] == :code }
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

    # Parser type identification for metadata
    def parser_type
      :legacy
    end
  end
end
