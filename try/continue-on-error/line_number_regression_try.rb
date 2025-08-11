# try/debug/line_number_regression_try.rb
# Test file to identify line number discrepancies between parsers
# NOTE: Some tests are designed to fail to verify accurate error line reporting

# Setup block - 15 lines to test offset calculation
puts "Starting setup"
x = 1
y = 2
z = 3

# More setup code
def helper_method
  "helper"
end

# Additional setup
setup_var = "test"
another_var = 42
final_setup = [1, 2, 3]

puts "Setup complete"

## TEST: Line number accuracy test - should fail at expected line 25
"this will fail"
#=> "this will not match"

## TEST: Second test to verify offset consistency - should fail at line 29
[1, 2, 3]
#=> [1, 2, 3, 4]

## TEST: Exception test for line number accuracy
1 / 0
#=!> error.is_a?(ZeroDivisionError)

## TEST: Regex match with exception
raise "Custom error message"
#=~> /Custom error/

## TEST: Type expectation with exception
raise ArgumentError, "wrong argument"
#=:> ArgumentError

# Final code block to test teardown boundary
puts "Tests complete"
