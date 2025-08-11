#!/usr/bin/env ruby
# Debug script to analyze line number behavior in the tryouts parser
# This file helps identify the source of the off-by-one line number bug

require_relative '../../lib/tryouts/parsers/prism_parser'
require_relative '../../lib/tryouts/parsers/enhanced_parser'

puts "=== Line Number Debug Analysis ==="
puts

# Create test content with explicit line numbers for reference
test_content = <<~RUBY
# Line 1: Initial comment
## TEST: First test case
# Line 3: Comment in test
a = 1 + 1
# Line 5: More code
b = 2 + 2
#=> 4
# Line 8: blank line follows

## TEST: Second test case
c = 3 + 3
#=> 6
#=> result

## TEST: Test with no expectations
d = 4 + 4
e = 5 + 5
RUBY

# Write to temp file for parsing
require 'tempfile'
temp_file = Tempfile.new(['debug_test', '.rb'])
temp_file.write(test_content)
temp_file.close

puts "Test content line-by-line (with 1-based line numbers for reference):"
test_content.lines.each_with_index do |line, idx|
  puts "#{(idx + 1).to_s.rjust(2)}: #{line.chomp}"
end
puts

begin
  # Parse the file
  parser = Tryouts::PrismParser.new(temp_file.path)
  testrun = parser.parse

  puts "=== Parser Analysis ==="
  puts "Total test cases found: #{testrun.test_cases.length}"
  puts

  testrun.test_cases.each_with_index do |test_case, idx|
    puts "--- Test Case #{idx + 1} ---"
    puts "Description: '#{test_case.description}'"
    puts "Line range (0-based): #{test_case.line_range.first}..#{test_case.line_range.last}"
    puts "Line range (1-based): #{test_case.line_range.first + 1}..#{test_case.line_range.last + 1}"
    puts "First expectation line (0-based): #{test_case.first_expectation_line}"
    puts "First expectation line (1-based): #{test_case.first_expectation_line + 1}"
    puts "Number of expectations: #{test_case.expectations.length}"

    if test_case.expectations.any?
      puts "Expectation types: #{test_case.expectations.map(&:type).join(', ')}"
    else
      puts "No expectations (first_expectation_line should equal line_range.first)"
    end

    puts "Source lines captured:"
    test_case.source_lines.each_with_index do |line, line_idx|
      actual_line_num = test_case.line_range.first + line_idx
      puts "  #{(actual_line_num + 1).to_s.rjust(2)} (0-based: #{actual_line_num}): #{line}"
    end
    puts
  end

  puts "=== Tokenization Debug ==="
  # Access the parser's internal state to see how tokens are created
  parser_debug = Tryouts::PrismParser.new(temp_file.path)
  lines = File.readlines(temp_file.path).map(&:chomp)
  parser_debug.instance_variable_set(:@lines, lines)
  parser_debug.instance_variable_set(:@source_content, test_content)

  # Call tokenize_content directly to see token line numbers
  tokens = parser_debug.send(:tokenize_content)

  puts "Tokens with line numbers:"
  tokens.each do |token|
    if [:description, :expectation, :exception_expectation, :code].include?(token[:type])
      puts "  #{token[:type]}: line #{token[:line]} (1-based: #{token[:line] + 1}) - '#{token[:content] || token[:type]}'"
    end
  end
  puts

  puts "=== Potential Issues ==="

  # Check for inconsistencies
  testrun.test_cases.each_with_index do |test_case, idx|
    puts "Test #{idx + 1} consistency check:"

    # Check if first_expectation_line matches the actual first expectation
    if test_case.expectations.any?
      # We need to find where the first expectation actually appears in the source
      expectation_lines = []
      test_case.source_lines.each_with_index do |line, line_idx|
        if line.match?(/^\s*#\s*=/)
          actual_line_num = test_case.line_range.first + line_idx
          expectation_lines << actual_line_num
        end
      end

      if expectation_lines.any?
        actual_first_expectation = expectation_lines.first
        reported_first_expectation = test_case.first_expectation_line

        puts "  Actual first expectation line (0-based): #{actual_first_expectation}"
        puts "  Reported first expectation line (0-based): #{reported_first_expectation}"

        if actual_first_expectation != reported_first_expectation
          puts "  *** INCONSISTENCY DETECTED! ***"
          puts "  Difference: #{reported_first_expectation - actual_first_expectation}"
        else
          puts "  ✓ Consistent"
        end
      end
    else
      puts "  No expectations - first_expectation_line should equal start_line"
      if test_case.first_expectation_line == test_case.line_range.first
        puts "  ✓ Consistent (both are #{test_case.first_expectation_line})"
      else
        puts "  *** INCONSISTENCY DETECTED! ***"
        puts "  first_expectation_line: #{test_case.first_expectation_line}"
        puts "  line_range.first: #{test_case.line_range.first}"
      end
    end
    puts
  end

ensure
  temp_file.unlink
end

puts "=== Summary ==="
puts "This debug script shows:"
puts "1. How line numbers are assigned during tokenization (0-based)"
puts "2. How line ranges are calculated for test cases"
puts "3. How first_expectation_line is determined"
puts "4. Whether there are inconsistencies between expected and actual line numbers"
puts
puts "If you see '*** INCONSISTENCY DETECTED! ***' messages above,"
puts "that indicates where the line number bug might be occurring."
