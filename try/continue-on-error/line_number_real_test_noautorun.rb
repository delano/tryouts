#!/usr/bin/env ruby
# Real test to verify line number consistency fix in practice
# This creates actual failing tests and checks error output for consistent line numbers

require_relative '../../lib/tryouts/parsers/prism_parser'
require_relative '../../lib/tryouts/parsers/enhacned_parser'
# Don't require verbose formatter to avoid dependency issues
require_relative '../../lib/tryouts/failure_collector'
require 'tempfile'

puts "=== Real Line Number Consistency Test ==="
puts

# Create a test file that will fail to verify line numbers in error output
test_content = <<~RUBY
## TEST: Multi-expectation failure test
x = 10
y = 20
z = 30
#=> 999
#=> 888
#=> 777
RUBY

# Write to temp file
temp_file = Tempfile.new(['real_line_test', '.rb'])
temp_file.write(test_content)
temp_file.close

puts "Test file content:"
File.readlines(temp_file.path).each_with_index do |line, idx|
  puts "#{(idx + 1).to_s.rjust(2)}: #{line.chomp}"
end
puts

begin
  # Parse the file
  parser = Tryouts::PrismParser.new(temp_file.path)
  testrun = parser.parse
  test_case = testrun.test_cases.first

  puts "=== Parser Results ==="
  puts "Test case description: '#{test_case.description}'"
  puts "Line range: #{test_case.line_range.first}..#{test_case.line_range.last} (0-based)"
  puts "First expectation line: #{test_case.first_expectation_line} (0-based)"
  puts "Number of expectations: #{test_case.expectations.length}"
  puts

  # Create failure collector to test the fix
  failure_collector = Tryouts::FailureCollector.new

  # Create mock result packet for a failed test
  result_packet = Struct.new(:test_case, :status, :actual_results, :expected_results, :failure_message) do
    def failed?; status == :failed; end
    def error?; status == :error; end
    def passed?; status == :passed; end
    def first_actual; actual_results&.first; end
    def first_expected; expected_results&.first; end
  end.new(test_case, :failed, [30], [999], "Test failed")

  # Add failure to collector
  failure_collector.add_failure(temp_file.path, result_packet)

  # Get the failure entry to check line number
  failures = failure_collector.failures_by_file
  failure_entry = failures[temp_file.path].first

  puts "=== Line Number Analysis ==="
  puts "Main display line number (first_expectation_line + 1): #{test_case.first_expectation_line + 1}"
  puts "Failure summary line number (FailureEntry.line_number): #{failure_entry.line_number}"
  puts "Failure summary display line number (line_number + 1): #{failure_entry.line_number + 1}"
  puts

  # Check if they match (they should after the fix)
  main_display_line = test_case.first_expectation_line + 1
  failure_summary_line = failure_entry.line_number + 1

  if main_display_line == failure_summary_line
    puts "✓ SUCCESS: Line numbers are consistent!"
    puts "  Both show line #{main_display_line} for the error"
  else
    puts "✗ INCONSISTENCY STILL EXISTS:"
    puts "  Main display would show: line #{main_display_line}"
    puts "  Failure summary shows: line #{failure_summary_line}"
    puts "  Difference: #{failure_summary_line - main_display_line}"
  end
  puts

  # Verify what line the numbers actually point to
  lines = File.readlines(temp_file.path)

  puts "=== Line Content Verification ==="
  main_line_content = lines[test_case.first_expectation_line]&.strip
  failure_line_content = lines[failure_entry.line_number]&.strip

  puts "Line #{main_display_line} content (main display): '#{main_line_content}'"
  puts "Line #{failure_summary_line} content (failure summary): '#{failure_line_content}'"

  if main_line_content == failure_line_content
    puts "✓ Both point to the same line content"
  else
    puts "✗ They point to different lines!"
  end
  puts

  # Show what the old behavior would have been
  old_behavior_line = test_case.line_range.last + 1
  old_line_content = lines[test_case.line_range.last]&.strip

  puts "=== Before Fix Comparison ==="
  puts "Old behavior would show line #{old_behavior_line}: '#{old_line_content}'"
  puts "New behavior shows line #{failure_summary_line}: '#{failure_line_content}'"

  if old_behavior_line != failure_summary_line
    puts "✓ Fix successfully changed the behavior"
    puts "  Difference from old: #{old_behavior_line - failure_summary_line}"
  else
    puts "✗ Fix didn't change the behavior"
  end

ensure
  temp_file.unlink
end

puts
puts "=== Test Summary ==="
puts "This test verifies that the fix in failure_collector.rb makes line numbers"
puts "consistent between the main error display and failure summary."
puts
puts "Expected behavior after fix:"
puts "- Both should point to the first expectation line"
puts "- Line numbers should be identical in both places"
puts "- Should be different from the old behavior (which used last line of range)"
