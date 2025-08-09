require 'prism'

class Tryouts
  # Helper utilities for AST-based parsing
  # These provide common operations for structural analysis
  module ASTHelpers
    # Extract all top-level statements (not nested in classes/modules/methods)
    def self.top_level_statements(ast)
      return [] unless ast&.statements&.body

      # Only statements not nested in defs/classes/modules
      ast.statements.body.select do |node|
        ![:def_node, :class_node, :module_node].include?(node.type)
      end
    end

    # Find comments that are structurally associated with a specific node
    def self.comments_for_node(comments, node, max_distance: 3)
      node_start = node.location.start_line
      node_end = node.location.end_line

      {
        preceding: comments.select do |c|
          c.location.end_line < node_start &&
          (node_start - c.location.end_line) <= max_distance
        end,
        following: comments.select do |c|
          c.location.start_line > node_end &&
          (c.location.start_line - node_end) <= max_distance
        end,
        inline: comments.select do |c|
          c.location.start_line >= node_start &&
          c.location.end_line <= node_end
        end
      }
    end

    # Check if a node represents a string literal (including heredocs)
    def self.string_literal?(node)
      [:string_node, :interpolated_string_node].include?(node.type)
    end

    # Check if a node is a heredoc specifically
    def self.heredoc?(node)
      return false unless node.respond_to?(:heredoc?)
      node.heredoc?
    end

    # Extract the actual content from string nodes
    def self.extract_string_content(node, source)
      case node.type
      when :string_node
        node.content
      when :interpolated_string_node
        # For heredocs and interpolated strings, extract from source
        start_offset = node.location.start_offset
        end_offset = node.location.end_offset
        source[start_offset...end_offset]
      else
        nil
      end
    end

    # Determine if a comment looks like a test expectation
    def self.expectation_comment?(comment_text)
      patterns = [
        /^#\s*=>/,          # Regular expectation: #=>
        /^#\s*==>/,         # Boolean true: #==>
        /^#\s*=\/=>/,       # Boolean false: #=/=>
        /^#\s*=\|>/,        # Boolean either: #=|>
        /^#\s*=:>/,         # Type check: #=:>
        /^#\s*=~>/,         # Regex match: #=~>
        /^#\s*=%>/,         # Performance: #=%>
        /^#\s*=!>/,         # Exception: #=!>
        /^#\s*=<>/,         # Intentional failure: #=<>
        /^#\s*=\d+>/        # Output expectation: #=1>
      ]

      patterns.any? { |pattern| comment_text.match?(pattern) }
    end

    # Determine if a comment looks like a test description
    def self.test_description_comment?(comment_text)
      # Remove leading # and whitespace
      content = comment_text.gsub(/^#\s*/, '').strip

      # Check for explicit test description patterns
      return true if content.start_with?('##') || content.match?(/^TEST\s*\d*:/)

      # Check for descriptive language patterns
      descriptive_patterns = [
        /\b(test|example|demonstrate|should|when|given|then)\b/i,
        /\b(verify|check|ensure|validate)\b/i
      ]

      # Must be substantial content (not just a short comment)
      content.length > 10 && descriptive_patterns.any? { |p| content.match?(p) }
    end

    # Check if content inside a string contains test-like patterns
    # This helps identify the HEREDOC edge case
    def self.contains_test_like_patterns?(content)
      return false if content.nil?

      # Look for patterns that might confuse line-based parsing
      test_patterns = [
        /^#\s*TEST\s*\d*:/m,     # Test descriptions
        /#\s*=>/m,               # Expectations
        /^#\s*[A-Z].*:/m         # Other description patterns
      ]

      test_patterns.any? { |pattern| content.match?(pattern) }
    end

    # Extract Ruby code from a node, excluding string literals
    def self.extract_code_content(node, source)
      return nil if string_literal?(node)

      start_offset = node.location.start_offset
      end_offset = node.location.end_offset
      source[start_offset...end_offset]
    end

    # Classify the role of a statement in the context of testing
    def self.classify_statement_role(node, comments, index, total_statements)
      node_comments = comments_for_node(comments, node)
      has_expectations = node_comments[:following].any? { |c| expectation_comment?(c.slice) }
      has_description = node_comments[:preceding].any? { |c| test_description_comment?(c.slice) }

      case
      when has_expectations && has_description
        :test_with_description
      when has_expectations
        :test_without_description
      when index == 0 && !has_expectations
        :potential_setup
      when index == total_statements - 1 && !has_expectations
        :potential_teardown
      else
        :code_statement
      end
    end
  end
end
