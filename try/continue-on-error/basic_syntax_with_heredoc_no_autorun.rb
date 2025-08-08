# try/core/basic_syntax_try.rb
# Tests for basic tryout syntax, expectations, and setup/teardown

# A friendly output message
@setup_text = <<~COMMENT
puts 'This puts is inside of a heredoc in the setup.'

# TEST 1: test matches result with expectation
a = 1 + 1
#=> 2
COMMENT

## TEST 2: This is the 2nd testcase in the file but it should
## be the first one that runs. The TEST 1 prior to this is
## inside of a HEREDOC.
a = 1
b = 2
a + b
# => 3

# This is a valid comment between testcases

# TEST 3: test expectation type matters
'foo'.class
#=> String

# TEST 4: instance variables can be used in expectations
@testcase_heredoc = <<~TESTCASE
@a = 1
#=> 3
TESTCASE
#=~> /@a = 1/

# ------

# TEST 4: test expectations can be commented out
'foo'
##=> 'this is a skipped test'

# Everything after this is run as teardown code

# Teardown
puts "If you can see this, teardown succeeded"
