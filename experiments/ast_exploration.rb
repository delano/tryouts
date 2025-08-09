#!/usr/bin/env ruby

require 'prism'
require 'pp'

class ASTExplorer
  def self.explore_heredoc_issue
    puts "=== AST Exploration: HEREDOC Edge Case ==="
    puts

    # This is the problematic pattern that confuses the line-based parser
    source = <<~RUBY
      @setup_text = <<~COMMENT
      puts 'This puts is inside of a heredoc in the setup.'

      # TEST 1: test matches result with expectation
      a = 1 + 1
      #=> 2
      COMMENT

      # This is a real test outside the heredoc
      b = 2 + 2
      #=> 4
    RUBY

    puts "Source code:"
    puts source
    puts "\n=== AST Analysis ==="

    result = Prism.parse(source)

    puts "Parse successful: #{!result.failure?}"
    puts "Errors: #{result.errors.map(&:message)}" if result.failure?
    puts

    puts "=== AST Structure ==="
    visitor = ExplorationVisitor.new(source)
    visitor.visit(result.value)

    puts "\n=== Key Insight ==="
    puts "The AST clearly distinguishes between:"
    puts "1. String literals (including heredoc content) - NOT executable code"
    puts "2. Actual Ruby expressions - executable code that can have expectations"
    puts
    puts "Line-based parsing sees '# TEST 1:' and '#=> 2' patterns and gets confused."
    puts "AST parsing knows these are just string content, not test definitions."
  end

  def self.explore_comment_types
    puts "\n=== Comment Analysis ==="

    source = <<~RUBY
      # This is a test description
      a = 1
      #=> 1

      # This is just a regular comment
      # More regular comments
      b = 2
      #=> 2
    RUBY

    result = Prism.parse(source)
    comments = result.comments

    puts "Found #{comments.size} comments:"
    comments.each_with_index do |comment, i|
      puts "#{i + 1}. Line #{comment.location.start_line}: #{comment.slice}"
    end
  end
end

class ExplorationVisitor < Prism::Visitor
  def initialize(source)
    @source = source
    @indent = 0
  end

  def visit_program_node(node)
    puts indent + "Program (#{node.statements.body.size} statements)"
    @indent += 2
    super
    @indent -= 2
  end

  def visit_local_variable_write_node(node)
    puts indent + "Variable assignment: #{node.name} (line #{node.location.start_line})"
    @indent += 2
    super
    @indent -= 2
  end

  def visit_interpolated_string_node(node)
    content_preview = extract_string_content(node)[0..50].gsub("\n", "\\n")
    puts indent + "HEREDOC String: '#{content_preview}...' (lines #{node.location.start_line}-#{node.location.end_line})"

    # This is the key insight: AST parsing can identify content INSIDE the string
    full_content = extract_string_content(node)
    if full_content.include?("#=> ")
      puts indent + "  ⚠️  Contains test-like patterns, but AST knows it's just string content!"
    end

    @indent += 2
    super
    @indent -= 2
  end

  def visit_string_node(node)
    content_preview = node.content[0..30].gsub("\n", "\\n")
    puts indent + "String: '#{content_preview}' (line #{node.location.start_line})"
    super
  end

  def visit_call_node(node)
    puts indent + "Method call: #{node.name} (line #{node.location.start_line})"
    @indent += 2
    super
    @indent -= 2
  end

  def visit_integer_node(node)
    puts indent + "Integer: #{node.value} (line #{node.location.start_line})"
    super
  end

  private

  def indent
    "  " * @indent
  end

  def extract_string_content(node)
    # Extract the actual content from a heredoc
    start_offset = node.location.start_offset
    end_offset = node.location.end_offset
    @source[start_offset...end_offset]
  end
end

if __FILE__ == $0
  ASTExplorer.explore_heredoc_issue
  ASTExplorer.explore_comment_types
end
