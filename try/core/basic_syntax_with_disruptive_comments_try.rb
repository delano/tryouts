# try/core/basic_syntax_with_disruptive_comments_try.rb
#
# frozen_string_literal: true

# Tests for basic tryout syntax, expectations, and setup/teardown

## SETUP

# This class that we won't use is helpful for testing the parser's ability
# to correctly identify tryouts testcases from random comments and other code.
class AnExtraTestClass < Object
  # A name field
  attr_accessor :name
end

# A friendly output message
puts 'If you see this the setup ran correctly.'

# Let's have another comment here to try to
# throw the parser off.

## TEST CASES

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

## TEARDOWN
# Everything after this is run as teardown code

# Teardown
puts "If you can see this, teardown succeeded"
