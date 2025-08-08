# try/core/basic_syntax_try.rb
# Tests for basic tryout syntax, expectations, and setup/teardown

# A friendly output message
puts 'If you see this the setup ran correctly.'

# Let's have another comment here to try to
# throw the parser off.

# TEST 1: test matches result with expectation
a = 1 + 1
#=> 2

## TEST 2: comments, tests, and expectations can
## contain multiple lines
a = 1
# A comment like this should not affect the test running or results
b = 2
# Sames here, even if it is spanning
# multiple
# lines.
a + b
# => 3
# => 2 + 1

# This is a valid comment between testcases

# TEST 3: test expectation type matters
'foo'.class
#=> String

# TEST 4: instance variables can be used in expectations
@a = 1
@a
#=> @a

# ------


# TEST 7: test expectations can be commented out
'foo'
##=> 'this is a skipped test'

# Everything after this is run as teardown code

# Teardown
puts "If you can see this, teardown succeeded"
