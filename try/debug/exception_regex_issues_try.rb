# try/debug/exception_regex_issues_try.rb
# Test file to demonstrate actual issues with exception expectations and regex matching

## TEST: Exception type expectation should check the class, not fail with error
raise ArgumentError, "wrong argument type"
#=:> ArgumentError

## TEST: Regex match should work with exception messages automatically
raise RuntimeError, "Custom error message with details"
#=~> /Custom error message/

## TEST: Exception type with different error class should work
raise StandardError, "generic error"
#=:> StandardError

## TEST: Regex match should work with different exception types
raise ZeroDivisionError, "divided by zero in calculation"
#=~> /divided by zero/

## TEST: Complex regex pattern with exception
raise ArgumentError, "Expected String but got Integer at line 42"
#=~> /Expected \w+ but got \w+ at line \d+/

## TEST: Exception expectation that should work correctly (current behavior)
1 / 0
#=!> error.is_a?(ZeroDivisionError)

## TEST: Current workaround that users have to do (should be unnecessary)
begin
  raise ArgumentError, "test message"
rescue => e
  e.message.include?("test message")
end
#==> true
