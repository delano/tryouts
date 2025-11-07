# try/continue-on-error/line_number_edge_cases_debug_noautorun.rb
#
# frozen_string_literal: true

#!/usr/bin/env ruby
# Debug script for edge cases that might trigger line number off-by-one bugs
# This tests scenarios that could cause inconsistencies in line number tracking

require_relative '../../lib/tryouts/parsers/legacy_parser'
require_relative '../../lib/tryouts/parsers/enhanced_parser'

puts "=== Line Number Edge Cases Debug ==="
puts

# Test case 1: Multiple blank lines and comments between code and expectations
puts "--- Edge Case 1: Multiple blank lines between code and expectations ---"
test_case_1 = <<~RUBY
## TEST: Gaps between code and expectations
a = 1

# comment

# another comment

#=> 1
RUBY

# Test case 2: Expectations immediately after code (no gaps)
puts "--- Edge Case 2: No gaps between code and expectations ---"
test_case_2 = <<~RUBY
## TEST: No gaps
b = 2
#=> 2
RUBY

# Test case 3: Multiple test cases with different spacing patterns
puts "--- Edge Case 3: Mixed spacing patterns ---"
test_case_3 = <<~RUBY
## TEST: First with gaps
x = 1

#=> 1

## TEST: Second no gaps
y = 2
#=> 2

## TEST: Third with comments
z = 3
# some comment
#=> 3
RUBY

# Test case 4: Expectations on consecutive lines
test_case_4 = <<~RUBY
## TEST: Multiple consecutive expectations
result = [1, 2, 3]
#=> result.length == 3
#=> result.first == 1
#=> result.last == 3
RUBY

# Test case 5: Different expectation types mixed
test_case_5 = <<~RUBY
## TEST: Mixed expectation types
arr = [1, 2, 3]
#=> arr.length
#==> arr.any?
#=/=> arr.empty?
#=:> Array
RUBY

def analyze_test_case(name, content)
  puts "#{name}:"
  puts "Content:"
  content.lines.each_with_index do |line, idx|
    puts "  #{(idx + 1).to_s.rjust(2)}: #{line.chomp}"
  end

  require 'tempfile'
  temp_file = Tempfile.new(['debug_edge', '.rb'])
  temp_file.write(content)
  temp_file.close

  begin
    parser = Tryouts::LegacyParser.new(temp_file.path)
    testrun = parser.parse

    puts "Found #{testrun.test_cases.length} test case(s):"

    testrun.test_cases.each_with_index do |test_case, idx|
      puts "  Test #{idx + 1}: '#{test_case.description}'"
      puts "    Line range: #{test_case.line_range.first}..#{test_case.line_range.last} (0-based)"
      puts "    Display range: #{test_case.line_range.first + 1}..#{test_case.line_range.last + 1} (1-based)"
      puts "    First expectation line: #{test_case.first_expectation_line} (0-based)"
      puts "    Display expectation line: #{test_case.first_expectation_line + 1} (1-based)"

      # Check for potential off-by-one issues
      if test_case.expectations.any?
        # Find actual expectation lines in source
        expectation_lines = []
        test_case.source_lines.each_with_index do |line, line_idx|
          if line.match?(/^\s*#\s*=/)
            actual_line_num = test_case.line_range.first + line_idx
            expectation_lines << actual_line_num
            puts "    Found expectation at line #{actual_line_num} (0-based): '#{line.strip}'"
          end
        end

        if expectation_lines.any?
          first_actual = expectation_lines.first
          reported = test_case.first_expectation_line

          if first_actual != reported
            puts "    *** MISMATCH: Actual first expectation at #{first_actual}, reported as #{reported}"
            puts "    *** This would cause line #{reported + 1} to be shown instead of #{first_actual + 1}"
          else
            puts "    ✓ Line numbers match correctly"
          end
        end
      end

      puts "    Source lines captured:"
      test_case.source_lines.each_with_index do |line, line_idx|
        actual_line_num = test_case.line_range.first + line_idx
        marker = line.match?(/^\s*#\s*=/) ? " <-- EXPECTATION" : ""
        puts "      #{(actual_line_num + 1).to_s.rjust(2)}: #{line}#{marker}"
      end
    end

  rescue => e
    puts "  ERROR: #{e.class}: #{e.message}"
  ensure
    temp_file.unlink
  end

  puts
end

# Run all test cases
analyze_test_case("Edge Case 1", test_case_1)
analyze_test_case("Edge Case 2", test_case_2)
analyze_test_case("Edge Case 3", test_case_3)
analyze_test_case("Edge Case 4", test_case_4)
analyze_test_case("Edge Case 5", test_case_5)

# Test case 6: Test what happens when we simulate the exact scenario described
puts "--- Edge Case 6: Simulating reported bug scenario ---"
# The bug report mentioned: "line number of the last expression of the testcase code
# instead of the line number of the first expectation"
test_case_6 = <<~RUBY
## TEST: Bug simulation
first_line = 1
second_line = 2
last_expression = 3
#=> 3
RUBY

analyze_test_case("Bug Simulation", test_case_6)

puts "=== Analysis Summary ==="
puts "This script tests edge cases that might trigger the line number bug:"
puts "1. Multiple blank lines between code and expectations"
puts "2. No gaps between code and expectations"
puts "3. Mixed spacing patterns across multiple tests"
puts "4. Multiple consecutive expectations"
puts "5. Different expectation types mixed together"
puts "6. Simulation of the exact bug scenario described"
puts
puts "Look for '*** MISMATCH ***' messages to identify problematic cases."
puts "The bug would manifest as showing the wrong line number in error messages."
