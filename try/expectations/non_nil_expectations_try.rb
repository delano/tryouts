# try/expectations/non_nil_expectations_try.rb
#
# frozen_string_literal: true

# Tests for the non-nil expectation syntax

puts 'Testing non-nil expectations...'

## TEST 1: Non-nil string passes
"hello world"
#=*>

## TEST 2: Non-nil number passes
42
#=*>

## TEST 3: Non-nil array passes
[1, 2, 3]
#=*>

## TEST 4: Non-nil hash passes
{ key: "value" }
#=*>

## TEST 5: Non-nil object passes
Time.now
#=*>

## TEST 6: Empty array is still non-nil (passes)
[]
#=*>

## TEST 7: Empty string is still non-nil (passes)
""
#=*>

## TEST 8: Zero is non-nil (passes)
0
#=*>

## TEST 9: False is non-nil (passes)
false
#=*>

puts 'Non-nil expectation tests completed'
