# try/debug/prism_inhouse_parser_prototype.rb
#
# frozen_string_literal: true

# Prototype implementation of PrismInhouseParser
# Demonstrates hybrid approach using Prism's inhouse comment extraction

require 'prism'

class PrismInhouseParserPrototype
  def initialize(source_path)
    @source_path = source_path
    @source = File.read(source_path)
  end

  def analyze
    puts "=== PrismInhouseParser Prototype Analysis ==="
    puts "File: #{@source_path}"
    puts

    # Phase 1: Inhouse comment extraction
    puts "1. Inhouse Comment Extraction:"
    comments = extract_comments_inhousely
    puts "Found #{comments.length} comments"

    comments.each_with_index do |comment, i|
      puts "  [#{i}] Line #{comment[:line]}: #{comment[:type]} -> '#{comment[:content]}'"
    end
    puts

    # Phase 2: HEREDOC handling (already solved by Prism!)
    puts "2. HEREDOC Handling:"
    puts "  ✅ Prism's inhouse comment extraction automatically excludes HEREDOC content"
    puts "  ✅ No additional filtering needed - comments inside strings aren't returned"
    puts

    # Phase 3: Group into test cases
    puts "3. Test Case Grouping:"
    test_cases = group_into_test_cases(comments)
    puts "Found #{test_cases.length} test cases"

    test_cases.each_with_index do |test_case, i|
      puts "  Test #{i + 1}:"
      puts "    Description: '#{test_case[:description]}'"
      puts "    Expectations: #{test_case[:expectations].length}"
      test_case[:expectations].each do |exp|
        puts "      #{exp[:type]}: '#{exp[:content]}'"
      end
    end

    {
      total_comments: comments.length,
      heredoc_handling: "✅ Automatic via Prism",
      test_cases: test_cases.length
    }
  end

  private

  def extract_comments_inhousely
    # Use Prism's inhouse comment extraction
    comments = Prism.parse_comments(@source)

    comments.map do |comment|
      content = comment.slice.strip
      line = comment.location.start_line

      # Simple pattern matching (no complex heuristics)
      case content
      when /^##\s*(.+)$/
        { type: :description, content: $1.strip, line: line }
      when /^#\s*TEST\s*\d*:\s*(.+)$/
        { type: :description, content: $1.strip, line: line }
      when /^#\s*=>\s*(.+)$/
        { type: :expectation, content: $1.strip, line: line }
      when /^#\s*=!>\s*(.+)$/
        { type: :exception_expectation, content: $1.strip, line: line }
      when /^#\s*=~>\s*(.+)$/
        { type: :regex_match_expectation, content: $1.strip, line: line }
      when /^#\s*==>\s*(.+)$/
        { type: :true_expectation, content: $1.strip, line: line }
      when %r{^#\s*=/=>\s*(.+)$}
        { type: :false_expectation, content: $1.strip, line: line }
      when /^#\s*=:>\s*(.+)$/
        { type: :result_type_expectation, content: $1.strip, line: line }
      when /^#\s*=%>\s*(.+)$/
        { type: :performance_time_expectation, content: $1.strip, line: line }
      else
        { type: :comment, content: content.sub(/^#\s*/, ''), line: line }
      end
    end
  end

# HEREDOC detection methods removed - not needed!
  # Prism's inhouse comment extraction automatically excludes comments inside HEREDOCs

  def group_into_test_cases(comments)
    test_cases = []
    current_test = nil

    # Simple grouping: description starts a test, expectations end it
    comments.each do |comment|
      case comment[:type]
      when :description
        # Finalize previous test if it exists
        test_cases << current_test if current_test && !current_test[:expectations].empty?

        # Start new test
        current_test = {
          description: comment[:content],
          expectations: []
        }
      when :expectation, :exception_expectation, :regex_match_expectation,
           :true_expectation, :false_expectation, :result_type_expectation,
           :performance_time_expectation
        # Add to current test if one exists
        if current_test
          current_test[:expectations] << {
            type: comment[:type],
            content: comment[:content]
          }
        end
      end
    end

    # Don't forget the last test
    test_cases << current_test if current_test && !current_test[:expectations].empty?
    test_cases
  end
end

# Test script
if __FILE__ == $0
  unless ARGV[0]
    puts "Usage: ruby #{__FILE__} <test_file.rb>"
    exit 1
  end

  file_path = ARGV[0]
  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    exit 1
  end

  prototype = PrismInhouseParserPrototype.new(file_path)
  result = prototype.analyze

  puts "\n=== Summary ==="
  puts "Total comments: #{result[:total_comments]}"
  puts "HEREDOC handling: #{result[:heredoc_handling]}"
  puts "Test cases: #{result[:test_cases]}"
  puts "\n🎉 Prism's inhouse comment extraction eliminates:"
  puts "   • Manual regex parsing (~50 patterns)"
  puts "   • Complex boundary detection logic"
  puts "   • HEREDOC edge case handling"
  puts "   • Multiple classification passes"
end
