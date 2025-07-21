# try/expectations/intentional_failure_try.rb

## TEST: Basic intentional failure - should pass when expectation fails
1 + 1
#=<> 3  # Pass: 1+1 ≠ 3, so intentional failure succeeds

## TEST: String intentional failure - should pass when string doesn't contain expected
"hello world"
#=<> result.include?("xyz")  # Pass: "hello world" doesn't contain "xyz"

## TEST: Array intentional failure - should pass when array condition is false
[1, 2, 3]
#=<> result.empty?  # Pass: array is not empty, so intentional failure succeeds

## TEST: Regex intentional failure - should pass when regex doesn't match
"hello123"
#=<> /^\d+$/  # Pass: "hello123" doesn't match digits-only pattern

## TEST: Boolean intentional failure - should pass when boolean expression is false
"test string"
#=<> result.length < 5  # Pass: "test string".length is not < 5
