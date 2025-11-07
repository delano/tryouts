# try/continue-on-error/line_number_analysis_and_fix_noautorun.rb
#
# frozen_string_literal: true

#!/usr/bin/env ruby
# Line Number Analysis and Fix Documentation
#
# This file documents the line number inconsistency bug found in Tryouts v3.0
# and the fix that was applied. Keep this file for future reference.

puts "=== LINE NUMBER BUG ANALYSIS AND FIX DOCUMENTATION ==="
puts
puts "Date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts

puts "=== PROBLEM DESCRIPTION ==="
puts "Users reported that line numbers shown in error messages were sometimes"
puts "off by one - specifically showing 'the line number of the last expression"
puts "of the testcase code instead of the line number of the first expectation'"
puts "or 'the number shown would be the line number of the first expectation-1'."
puts

puts "=== ROOT CAUSE ANALYSIS ==="
puts
puts "The bug was caused by inconsistent line number references in error reporting:"
puts
puts "1. MAIN ERROR DISPLAY (verbose.rb:139):"
puts "   location = test_case.first_expectation_line + 1"
puts "   → Used first expectation line (CORRECT)"
puts
puts "2. FAILURE SUMMARY (verbose.rb:64, compact.rb:65):"
puts "   location = failure.line_number"
puts "   → Used FailureEntry.line_number which returned line_range.last (INCORRECT)"
puts
puts "This caused the main display and failure summary to show different line numbers"
puts "for the same failed test, with the failure summary potentially pointing to"
puts "the LAST expectation instead of the FIRST expectation."
puts

puts "=== TECHNICAL DETAILS ==="
puts
puts "Line Number Storage Convention in Tryouts:"
puts "- Parser uses 0-based indexing from each_with_index"
puts "- All internal line numbers stored as 0-based throughout pipeline"
puts "- Display adds +1 to convert to 1-based line numbers for users"
puts
puts "Example with multiple expectations:"
puts "  Line 1: ## TEST: Sample"
puts "  Line 2: a = 1"
puts "  Line 3: b = 2"
puts "  Line 4: #=> 999  <- FIRST expectation"
puts "  Line 5: #=> 888  <- LAST expectation"
puts
puts "Before fix:"
puts "- Main display: Line 4 (first_expectation_line=3, +1 = 4)"
puts "- Failure summary: Line 5 (line_range.last=4, +1 = 5)"
puts "- INCONSISTENT by 1 line"
puts
puts "After fix:"
puts "- Main display: Line 4 (first_expectation_line=3, +1 = 4)"
puts "- Failure summary: Line 4 (first_expectation_line=3, +1 = 4)"
puts "- CONSISTENT ✓"
puts

puts "=== FIXES APPLIED ==="
puts
puts "Fix 1: lib/tryouts/failure_collector.rb"
puts "  Changed FailureEntry.line_number method:"
puts
puts "  BEFORE:"
puts "    def line_number"
puts "      test_case.line_range&.last || test_case.first_expectation_line || 0"
puts "    end"
puts
puts "  AFTER:"
puts "    def line_number"
puts "      test_case.first_expectation_line || test_case.line_range&.first || 0"
puts "    end"
puts
puts "Fix 2: lib/tryouts/cli/formatters/verbose.rb"
puts "  Added +1 conversion for failure summary display:"
puts
puts "  BEFORE:"
puts "    location = \"#{pretty_path}:#{failure.line_number}\""
puts
puts "  AFTER:"
puts "    location = \"#{pretty_path}:#{failure.line_number + 1}\""
puts
puts "Fix 3: lib/tryouts/cli/formatters/compact.rb"
puts "  Added +1 conversion for failure summary display:"
puts
puts "  BEFORE:"
puts "    location = \"#{pretty_path}:#{failure.line_number}\""
puts
puts "  AFTER:"
puts "    location = \"#{pretty_path}:#{failure.line_number + 1}\""
puts

puts "=== VERIFICATION ==="
puts
puts "The fixes were verified by:"
puts "1. Creating test cases with multiple expectations"
puts "2. Confirming main display and failure summary show identical line numbers"
puts "3. Running full test suite to ensure no regressions"
puts "4. Testing fallback behavior for edge cases"
puts
puts "Result: All line number displays now consistently point to the"
puts "first expectation line of failed tests."
puts

puts "=== DESIGN PRINCIPLES MAINTAINED ==="
puts
puts "The fixes maintain the established codebase conventions:"
puts "- Internal storage: 0-based indices (from array indexing)"
puts "- Display conversion: +1 for 1-based user-facing line numbers"
puts "- Consistent reference: Both displays use first_expectation_line"
puts "- Graceful fallbacks: Handle cases with no expectations"
puts

puts "=== EDGE CASES HANDLED ==="
puts
puts "1. Multiple expectations: Points to first, not last"
puts "2. Single expectation: Consistent behavior maintained"
puts "3. No expectations: Fallback to line_range.first"
puts "4. Nil values: Ultimate fallback to 0"
puts

puts "=== FUTURE MAINTENANCE ==="
puts
puts "If line number issues arise
 again, check:"
puts "1. All new line number usages follow 0-based internal, 1-based display pattern"
puts "2. Error reporting uses consistent reference points (first_expectation_line)"
puts "3. Display formatters include +1 conversion for user-facing output"
puts
puts "Reference files for debugging:"
puts "- try/continue-on-error/line_number_debug_noautorun.rb"
puts "- try/continue-on-error/line_number_edge_cases_debug_noautorun.rb"
puts "- try/continue-on-error/line_number_real_test_noautorun.rb"
puts

puts "=== TEST VERIFICATION EXAMPLE ==="
puts

puts "To verify the fix is working, create a test with multiple expectations:"
puts
puts "## TEST: Multi-expectation test"
puts "x = 1"
puts "y = 2"
puts "#=> 999  # This line should be shown in ALL error displays"
puts "#=> 888"
puts
puts "Both the main error display and failure summary should point to"
puts "the same line number (the line with '#=> 999')."
puts

puts "=== END DOCUMENTATION ==="
