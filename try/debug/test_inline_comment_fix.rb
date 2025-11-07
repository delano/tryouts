# try/debug/test_inline_comment_fix.rb
#
# frozen_string_literal: true

# Test inline comment exclusion

## TEST: Inline comments should not be treated as expectations
result = 1 + 1  # => This should NOT be treated as an expectation
result
#=> 2

## TEST: Natural language comments with equals should work
# This comment has = sign in natural language and should be fine
# Setup: batch_size = 100
value = "test"
#=> "test"
