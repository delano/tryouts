# try/debug/test_inline_comment_fix.rb
#
# frozen_string_literal: true

# An expectation can trail the statement it asserts on, written `#=>` or
# `# =>`. A trailing comment without the arrow is a plain comment.

## TEST: An inline '# =>' is an expectation on the statement it trails
sum = 1 + 1  # => 2

## TEST: A trailing comment without the arrow is not an expectation
total = (1 + 1) * 10  # ten times the sum
total
#=> 20

## TEST: Natural language comments with equals should work
# This comment has = sign in natural language and should be fine
# Setup: batch_size = 100
value = "test"
#=> "test"
