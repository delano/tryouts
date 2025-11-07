# lib/tryouts/parsers/legacy_parser.rb
#
# frozen_string_literal: true

require_relative '../test_case'
require_relative 'base_parser'

class Tryouts
  # Legacy parser using line-by-line regex parsing for compatibility
  #
  # The LegacyParser provides a simpler, more straightforward approach to parsing
  # tryout files using sequential line-by-line processing with pattern matching.
  # While less sophisticated than the EnhancedParser, it offers predictable behavior
  # and serves as a fallback option for edge cases.
  #
  # @example Basic usage
  #   parser = Tryouts::LegacyParser.new(source_code, file_path)
  #   testrun = parser.parse
  #   puts testrun.test_cases.length
  #
  # @example Using legacy parser explicitly
  #   # In CLI: tryouts --legacy-parser my_test.rb
  #   # Or programmatically:
  #   parser = Tryouts::LegacyParser.new(source, file)
  #   result = parser.parse
  #
  # @!attribute [r] parser_type
  #   @return [Symbol] Returns :legacy to identify parser type
  #
  # ## Characteristics
  #
  # ### 1. Simple Line-by-Line Processing
  # - Processes each line sequentially with pattern matching
  # - Straightforward regex-based approach
  # - Easy to understand and debug parsing logic
  #
  # ### 2. Pattern Matching Classification
  # - Uses Ruby 3.4+ pattern matching (`case/in`) for token classification
  # - Modern syntax while maintaining simple parsing approach
  # - Consistent with EnhancedParser's classification logic
  #
  # ### 3. Compatibility Focus
  # - Maintains backward compatibility with older tryout files
  # - Provides fallback parsing when EnhancedParser encounters issues
  # - Useful for debugging parser-specific problems
  #
  # ## Limitations
  #
  # ### 1. HEREDOC Vulnerability
  # - Cannot distinguish between real comments and content inside HEREDOCs
  # - May incorrectly parse string content as tryout syntax
  # - Requires careful handling of complex Ruby syntax
  #
  # ### 2. Limited Inline Comment Support
  # - Basic handling of lines with both code and comments
  # - Less sophisticated than EnhancedParser's multi-comment support
  #
  # ## When to Use
  #
  # - **Debugging**: When EnhancedParser produces unexpected results
  # - **Compatibility**: With older Ruby versions or edge cases
  # - **Simplicity**: When predictable line-by-line behavior is preferred
  # - **Fallback**: As a secondary parsing option
  #
  # @see EnhancedParser For robust syntax-aware parsing (recommended default)
  # @see BaseParser For shared parsing functionality
  # @since 3.0.0
  class LegacyParser < Tryouts::Parsers::BaseParser

    # Parse source code into a Testrun using line-by-line processing
    #
    # This method provides sequential line-by-line parsing that processes each
    # line with pattern matching to classify tokens. While simpler than
    # EnhancedParser, it may be vulnerable to HEREDOC content parsing issues.
    #
    # @return [Tryouts::Testrun] Structured test data with setup, test cases, teardown, and warnings
    # @raise [Tryouts::TryoutSyntaxError] If source contains syntax errors or strict mode violations
    def parse
      return handle_syntax_errors if @prism_result.failure?

      tokens           = tokenize_content
      test_boundaries  = find_test_case_boundaries(tokens)
      tokens           = classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
      test_blocks      = group_into_test_blocks(tokens)
      process_test_blocks(test_blocks)
    end

    private

    # Tokenize content using sequential line-by-line pattern matching
    #
    # Processes each line of source code individually, applying pattern matching
    # to classify it as code, comment, expectation, etc. This approach is simple
    # and predictable but cannot distinguish between real comments and content
    # inside string literals or HEREDOCs.
    #
    # @return [Array<Hash>] Array of token hashes with keys :type, :content, :line, etc.
    # @example Token structure
    #   [
    #     { type: :description, content: "Test case description", line: 5 },
    #     { type: :code, content: "result = calculate(x)", line: 6 },
    #     { type: :expectation, content: "42", line: 7, ast: <Prism::Node> }
    #   ]
    # @note Potential_descriptions are later reclassified based on test boundaries
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
                in line if looks_like_malformed_expectation?(line) # Comprehensive malformed expectation detection
                  detected_syntax = extract_malformed_syntax(line)
                  add_warning(ParserWarning.malformed_expectation(
                    line_number: index + 1,
                    syntax: detected_syntax,
                    context: line.strip
                  ))
                  { type: :malformed_expectation, syntax: detected_syntax, content: line.strip, line: index }
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

    # Detect if a comment looks like a malformed expectation attempt
    # This catches patterns that suggest someone tried to write an expectation
    # but got the syntax wrong (missing parts, wrong spacing, extra characters, etc.)
    def looks_like_malformed_expectation?(content)
      # Skip if it's already handled by specific patterns above
      return false if content.match?(/^##\s*/) # Description
      return false if content.match?(/^#\s*TEST\s*\d*:\s*/) # TEST format
      return false if content.match?(/^##\s*=>\s*/) # Commented out expectation

      # Look for patterns that suggest expectation attempts:
      # 1. Contains = and/or > in suspicious positions
      # 2. Has spaces around = or > suggesting misunderstanding
      # 3. Missing > or = from what looks like expectation syntax
      # 4. Extra characters in expectation-like patterns

      content.match?(/^#\s*([=><]|.*[=><])/) && # Contains =, >, or < after #
      !content.match?(/^#\s*[^=><]*$/) # Not just a regular comment without expectation chars
    end

    # Extract the malformed syntax portion for warning display
    def extract_malformed_syntax(content)
      # Try to identify what the user was attempting to write
      case content
      when /^#\s*([=><][^=><]*[=><].*?)(\s|$)/ # Pattern with expectation chars
        $1.strip
      when /^#\s*([=><].*?)(\s|$)/ # Simple pattern starting with expectation char
        $1.strip
      when /^#\s*(.*?[=><].*?)(\s|$)/ # Pattern containing expectation chars
        $1.strip
      else
        # Fallback: show the part after #
        content.sub(/^#\s*/, '').split(/\s/).first || 'unknown'
      end
    end

    # Parser type identification for metadata
    def parser_type
      :legacy
    end
  end
end
