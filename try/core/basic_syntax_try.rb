# try/core/basic_syntax_try.rb
#
# frozen_string_literal: true

# Tests for basic tryout syntax, expectations, and setup/teardown

puts 'If you see this the setup ran correctly.'

# TEST 1: test matches result with expectation
a = 1 + 1
#=> 2

## TEST 2: comments, tests, and expectations can
## contain multiple lines
a = 1
b = 2
a + b
# => 3
# => 2 + 1

# TEST 3: test expectation type matters
'foo'.class
#=> String

# TEST 4: instance variables can be used in expectations
@a = 1
@a
#=> @a

# TEST 5: test ignores blank lines before expectations
@a += 1
'foo'

#=> 'foo'

# TEST 6: test allows whiny expectation markers for textmate users *sigh*
'foo'
# =>  'foo'

# TEST 7: test expectations can be commented out
'foo'
##=> 'this is a skipped test'

# Everything after this is run as teardown code

x = begin
  raise
rescue StandardError
  'if you can see this, teardown succeeded'
end  # noqa
puts x
