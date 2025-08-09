#!/usr/bin/env ruby

require_relative '../lib/tryouts'
require_relative '../lib/tryouts/prism_parser'
require_relative '../lib/tryouts/ast_prism_parser'

class ParserComparison
  def self.compare_parsers(file_path)
    puts "=== Parser Comparison: #{file_path} ==="
    puts

    begin
      # Parse with existing line-based parser
      puts "📝 Parsing with existing PrismParser..."
      existing_parser = Tryouts::PrismParser.new(file_path)
      existing_result = existing_parser.parse

      # Parse with new AST parser
      puts "🌳 Parsing with new AstPrismParser..."
      ast_parser = Tryouts::AstPrismParser.new(file_path)
      ast_result = ast_parser.parse

      # Compare results
      puts "\n=== Comparison Results ==="
      compare_test_structure(existing_result, ast_result)

      puts "\n=== AST Parser Insights ==="
      show_ast_insights(ast_parser)

      puts "\n=== Learning Summary ==="
      show_learning_insights(existing_result, ast_result, ast_parser)

    rescue => e
      puts "❌ Error during comparison: #{e.message}"
      puts e.backtrace.first(5)
    end
  end

  def self.test_heredoc_edge_case
    puts "=== HEREDOC Edge Case Test ==="
    puts

    # Create a test file with the problematic HEREDOC pattern
    test_file = create_heredoc_test_file

    begin
      puts "Testing problematic HEREDOC pattern..."
      puts "File content:"
      puts File.read(test_file)
      puts "\n" + "=" * 50

      compare_parsers(test_file)

    ensure
      # Clean up test file
      File.delete(test_file) if File.exist?(test_file)
    end
  end

  private

  def self.compare_test_structure(existing, ast)
    puts "Test Case Count:"
    puts "  Existing: #{existing.test_cases.size}"
    puts "  AST:      #{ast.test_cases.size}"
    puts "  Match:    #{existing.test_cases.size == ast.test_cases.size ? '✅' : '❌'}"
    puts

    puts "Setup Code:"
    puts "  Existing: #{existing.setup.code.lines.count} lines"
    puts "  AST:      #{ast.setup.code.lines.count} lines"
    puts "  Match:    #{existing.setup.code == ast.setup.code ? '✅' : '❌'}"
    puts

    puts "Teardown Code:"
    puts "  Existing: #{existing.teardown.code.lines.count} lines"
    puts "  AST:      #{ast.teardown.code.lines.count} lines"
    puts "  Match:    #{existing.teardown.code == ast.teardown.code ? '✅' : '❌'}"
    puts

    # Compare individual test cases
    max_tests = [existing.test_cases.size, ast.test_cases.size].max
    puts "Individual Test Case Comparison:"

    (0...max_tests).each do |i|
      existing_test = existing.test_cases[i]
      ast_test = ast.test_cases[i]

      if existing_test && ast_test
        desc_match = existing_test.description == ast_test.description
        expectations_match = existing_test.expectations.size == ast_test.expectations.size

        puts "  Test #{i + 1}:"
        puts "    Description: #{desc_match ? '✅' : '❌'}"
        puts "    Expectations: #{expectations_match ? '✅' : '❌'} (#{existing_test.expectations.size} vs #{ast_test.expectations.size})"
      else
        puts "  Test #{i + 1}: ❌ Missing in #{existing_test ? 'AST' : 'existing'} parser"
      end
    end
  end

  def self.show_ast_insights(ast_parser)
    debug_info = ast_parser.debug_info
    insights = ast_parser.structural_insights

    puts "Debug Information:"
    puts "  Nodes visited: #{debug_info[:nodes_visited]}"
    puts "  String nodes found: #{debug_info[:string_nodes_found]}"
    puts "  HEREDOCs found: #{debug_info[:heredocs_found]}"
    puts "  Test patterns in strings: #{debug_info[:potential_test_patterns_in_strings]}"
    puts

    puts "Structural Analysis:"
    puts "  Total statements: #{insights[:total_statements]}"
    puts "  Executable statements: #{insights[:executable_statements]}"
    puts "  String literals: #{insights[:string_literals].size}"

    if insights[:string_literals].any? { |s| s[:contains_test_patterns] }
      puts "\n🔍 String literals with test-like patterns:"
      insights[:string_literals].each do |literal|
        if literal[:contains_test_patterns]
          puts "    Line #{literal[:line]}: #{literal[:type]} (contains test patterns!)"
        end
      end
    end
  end

  def self.show_learning_insights(existing_result, ast_result, ast_parser)
    debug_info = ast_parser.debug_info

    puts "Key Learning Points:"

    # Test count comparison
    if existing_result.test_cases.size != ast_result.test_cases.size
      puts "  🎯 Test count differs - AST parsing may have resolved edge cases"
    else
      puts "  ✅ Test count matches - both parsers agree on test structure"
    end

    # HEREDOC insights
    if debug_info[:heredocs_found] > 0
      if debug_info[:potential_test_patterns_in_strings] > 0
        puts "  🔍 Found HEREDOCs with test-like patterns - AST correctly identified as string content"
        puts "      This is the type of edge case that line-based parsing struggles with!"
      else
        puts "  📋 Found HEREDOCs without confusing patterns"
      end
    end

    # Structural understanding
    puts "  🌳 AST parsing provides structural understanding vs pattern matching"
    puts "  📊 Visited #{debug_info[:nodes_visited]} AST nodes for complete analysis"

    # Performance insight
    puts "  ⚡ Trade-off: AST parsing is more accurate but requires full tree traversal"
  end

  def self.create_heredoc_test_file
    content = <<~RUBY
      # Setup with problematic HEREDOC
      @setup_text = <<~COMMENT
      puts 'This puts is inside of a heredoc in the setup.'

      # TEST 1: test matches result with expectation
      a = 1 + 1
      #=> 2
      COMMENT

      ## Real test outside the heredoc
      b = 2 + 2
      #=> 4

      # More test-like content in another heredoc
      @instructions = <<~DOC
      ## TEST: This looks like a test but isn't
      result = some_method
      #=> "expected result"
      DOC

      ## Another real test
      c = 3 + 3
      #=> 6
    RUBY

    test_file = '/tmp/heredoc_test.rb'
    File.write(test_file, content)
    test_file
  end
end

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby parser_comparison.rb <path_to_test_file>"
    puts "   OR: ruby parser_comparison.rb --heredoc-test"
    puts
    puts "Examples:"
    puts "  ruby parser_comparison.rb try/core/basic_syntax_try.rb"
    puts "  ruby parser_comparison.rb --heredoc-test"
  elsif ARGV[0] == '--heredoc-test'
    ParserComparison.test_heredoc_edge_case
  else
    ParserComparison.compare_parsers(ARGV[0])
  end
end
