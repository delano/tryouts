# lib/tryouts/parsers/enhanced_parser.rb

# Enhanced parser using Prism's inhouse comment extraction capabilities
# Drop-in replacement for PrismParser that eliminates HEREDOC parsing issues

require_relative '../test_case'
require_relative 'base_parser'

class Tryouts
  # Enhanced parser that replaces manual line-by-line parsing with inhouse Prism APIs
  # while maintaining full compatibility with the original parser's logic structure
  class EnhancedParser < Tryouts::Parsers::BaseParser

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
      when /^#\s*=\*>\s*(.*)$/
        { type: :non_nil_expectation, content: $1.strip, line: line_number - 1 }
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

    # Parser type identification for metadata
    def parser_type
      :enhanced
    end
  end
end
