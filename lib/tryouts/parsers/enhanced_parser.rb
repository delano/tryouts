# lib/tryouts/parsers/enhanced_parser.rb

require_relative '../test_case'
require_relative 'base_parser'

class Tryouts
  # Enhanced parser using Prism's native comment extraction for robust parsing
  #
  # The EnhancedParser is the default parser that provides syntax-aware comment
  # extraction by leveraging Ruby's official Prism parser. This approach eliminates
  # common parsing issues found in regex-based parsers, particularly with complex
  # Ruby syntax.
  #
  # @example Basic usage
  #   parser = Tryouts::EnhancedParser.new(source_code, file_path)
  #   testrun = parser.parse
  #   puts testrun.test_cases.length
  #
  # @example Problematic code that EnhancedParser handles correctly
  #   source = <<~RUBY
  #     ## Test HEREDOC handling
  #     sql = <<~SQL
  #       SELECT * FROM users
  #       -- This is NOT a tryout comment
  #       #=> This is NOT a tryout expectation
  #     SQL
  #     puts sql.length
  #     #=> Integer  # This IS a real expectation
  #   RUBY
  #
  # @!attribute [r] parser_type
  #   @return [Symbol] Returns :enhanced to identify parser type
  #
  # ## Key Benefits over LegacyParser
  #
  # ### 1. HEREDOC Safety
  # - Uses Prism's `parse_comments()` to extract only actual Ruby comments
  # - Automatically excludes content inside string literals, HEREDOCs, and interpolation
  # - Prevents false positive expectation detection
  #
  # ### 2. Inline Comment Handling
  # - Correctly handles lines with both code and comments
  # - Supports multiple comments per line with proper positioning
  # - Emits separate tokens for code and comment content
  #
  # ### 3. Syntax Awareness
  # - Leverages Ruby's official parser for accurate code understanding
  # - Handles complex Ruby syntax edge cases reliably
  # - More robust than regex-based parsing approaches
  #
  # ### 4. Performance
  # - Uses optimized C-based Prism parsing for comment extraction
  # - Efficient handling of large files with complex syntax
  #
  # ## Pattern Matching
  # Uses Ruby 3.4+ pattern matching (`case/in`) for token classification,
  # providing clean, modern syntax for expectation type detection.
  #
  # @see LegacyParser For simpler regex-based parsing (legacy compatibility)
  # @see BaseParser For shared parsing functionality
  # @since 3.2.0
  class EnhancedParser < Tryouts::Parsers::BaseParser

    # Parse source code into a Testrun using Prism-based comment extraction
    #
    # This method provides the main parsing logic that converts raw Ruby source
    # code containing tryout syntax into structured test cases. Uses Prism's
    # native comment extraction to avoid HEREDOC parsing issues.
    #
    # @return [Tryouts::Testrun] Structured test data with setup, test cases, teardown, and warnings
    # @raise [Tryouts::TryoutSyntaxError] If source contains syntax errors or strict mode violations
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

    # Extract and tokenize comments using Prism's native comment extraction
    #
    # This method replaces manual line-by-line regex parsing with Prism's
    # built-in comment extraction capabilities. The key benefit is that
    # `Prism.parse_comments()` only returns actual Ruby comments, automatically
    # excluding content inside string literals, HEREDOCs, and interpolations.
    #
    # @return [Array<Hash>] Array of token hashes with keys :type, :content, :line, etc.
    # @example Token structure
    #   [
    #     { type: :description, content: "Test case description", line: 5 },
    #     { type: :code, content: "result = calculate(x)", line: 6 },
    #     { type: :expectation, content: "42", line: 7, ast: <Prism::Node> }
    #   ]
    def tokenize_content_with_inhouse_extraction
      tokens = []

      # Get all comments using inhouse Prism extraction
      comments        = Prism.parse_comments(@source)
      comment_by_line = comments.group_by { |comment| comment.location.start_line }

      # Process each line, handling multiple comments per line
      @lines.each_with_index do |line, index|
        line_number = index + 1

        if (comments_for_line = comment_by_line[line_number]) && !comments_for_line.empty?
          emitted_code = false
          comments_for_line.sort_by! { |c| c.location.start_column }
          comments_for_line.each do |comment|
            comment_content = comment.slice.strip
            if comment.location.start_column > 0
              unless emitted_code
                tokens << { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
                emitted_code = true
              end
              # Inline comment may carry expectations; classify it too
              tokens << classify_comment_inhousely(comment_content, line_number)
            else
              tokens << classify_comment_inhousely(comment_content, line_number)
            end
          end
          next
        end

        # Handle non-comment lines (blank lines and code)
        token = case line
                when /^\s*$/
                  { type: :blank, line: index }
                else
                  { type: :code, content: line, line: index, ast: parse_ruby_line(line) }
                end
        tokens << token
      end

      tokens
    end

    # Classify comment content into specific token types using pattern matching
    #
    # Takes a raw comment string and determines what type of tryout token it
    # represents (description, expectation, etc.). Uses Ruby 3.4+ pattern matching
    # for clean, maintainable classification logic.
    #
    # @param content [String] The comment content (including # prefix)
    # @param line_number [Integer] 1-based line number for error reporting
    # @return [Hash] Token hash with :type, :content, :line and other type-specific keys
    #
    # @example Valid expectation
    #   classify_comment_inhousely("#=> 42", 10)
    #   # => { type: :expectation, content: "42", line: 9, ast: <Prism::Node> }
    #
    # @example Malformed expectation (triggers warning)
    #   classify_comment_inhousely("#=INVALID> 42", 10)
    #   # => { type: :malformed_expectation, syntax: "INVALID", content: "42", line: 9 }
    #   # Also adds warning to parser's warning collection
    #
    # @example Test description
    #   classify_comment_inhousely("## Test basic math", 5)
    #   # => { type: :description, content: "Test basic math", line: 4 }
    def classify_comment_inhousely(content, line_number)
      case content
      in /^##\s*(.*)$/ # Test description format: ## description
        { type: :description, content: $1.strip, line: line_number - 1 }
      in /^#\s*TEST\s*\d*:\s*(.*)$/  # rubocop:disable Lint/DuplicateBranch
        { type: :description, content: $1.strip, line: line_number - 1 }
      in /^#\s*=!>\s*(.*)$/ # Exception expectation
        { type: :exception_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=<>\s*(.*)$/ # Intentional failure expectation
        { type: :intentional_failure_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*==>\s*(.*)$/ # Boolean true expectation
        { type: :true_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in %r{^#\s*=/=>\s*(.*)$} # Boolean false expectation
        { type: :false_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=\|>\s*(.*)$/ # Boolean (true or false) expectation
        { type: :boolean_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=\*>\s*(.*)$/ # Non-nil expectation
        { type: :non_nil_expectation, content: $1.strip, line: line_number - 1 }
      in /^#\s*=:>\s*(.*)$/ # Result type expectation
        { type: :result_type_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=~>\s*(.*)$/ # Regex match expectation
        { type: :regex_match_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=%>\s*(.*)$/ # Performance time expectation
        { type: :performance_time_expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=(\d+)>\s*(.*)$/ # Output expectation (stdout/stderr with pipe number)
        { type: :output_expectation, content: $2.strip, pipe: $1.to_i, line: line_number - 1, ast: parse_expectation($2.strip) }
      in /^#\s*=>\s*(.*)$/ # Regular expectation
        { type: :expectation, content: $1.strip, line: line_number - 1, ast: parse_expectation($1.strip) }
      in /^#\s*=([^>=:!~%*|\/\s]+)>\s*(.*)$/ # Malformed expectation - invalid characters between = and >
        syntax = $1
        content_part = $2.strip
        add_warning(ParserWarning.malformed_expectation(
          line_number: line_number,
          syntax: syntax,
          context: content.strip
        ))
        { type: :malformed_expectation, syntax: syntax, content: content_part, line: line_number - 1 }
      in /^##\s*=>\s*(.*)$/ # Commented out expectation (should be ignored)
        { type: :comment, content: '=>' + $1.strip, line: line_number - 1 }
      in /^#\s*(.*)$/ # Single hash comment - potential description
        { type: :potential_description, content: $1.strip, line: line_number - 1 }
      else # Unknown comment format
        { type: :comment, content: content.sub(/^#\s*/, ''), line: line_number - 1 }
      end
    end

    # Parser type identification for metadata
    def parser_type
      :enhanced
    end
  end
end
