# try/debug/test_malformed_detection.rb
#
# frozen_string_literal: true

# Test malformed expectation detection

## TEST: Valid expectation should work
result = 1 + 1
#=> 2

## TEST: These should trigger malformed expectation warnings
another_result = 2 + 2
# = > 4
# =x> invalid

## TEST: Natural language should be fine
# This assignment = value should not trigger warnings
final_result = 3 + 3
#=> 6
