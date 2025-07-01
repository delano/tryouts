# try/step1_try.rb

puts 'If you see this the setup ran correctly.'

# test matches single quote description start
1
#=> 1

# TEST 2: test matches result with expectation
2
#=> 2

## TEST 3: comments, tests, and expectations can
## contain multiple lines
3
3
# => 3
# => 2 + 1

# TEST 4: test expectation type matters
'foo'.class
#=> String

# TEST 5: instance variables can be used in expectations
@a = 1
#=> @a

# TEST 6: test ignores blank lines before expectations
@a += 1

#=> 'foo'

# TEST 7: test allows whiny expectation markers for textmate users *sigh*
'foo'
# =>  'foo'

# TEST 8: test expectations can be commented out
'this is a skipped test'
##=> 'this is a skipped test'

# Everything after this is run as teardown code

x = begin
  raise
rescue StandardError
  'if you can see this, teardown succeeded'
end
puts x
