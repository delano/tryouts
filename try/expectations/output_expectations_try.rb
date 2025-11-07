# try/expectations/output_expectations_try.rb
#
# frozen_string_literal: true

## TEST: Simple stdout string contains
puts "Hello, World!"
#=1> "Hello"

## TEST: Stdout regex pattern match
puts "Testing output capture: 12345"
#=1> /Testing.*\d+/

## TEST: Multiple stdout expectations
puts "Line 1"; puts "Line 2"
#=1> "Line 1"
#=1> "Line 2"

## TEST: Simple stderr string contains
$stderr.puts "Warning message"
#=2> "Warning"

## TEST: Stderr regex pattern match
$stderr.puts "Error: File not found (404)"
#=2> /Error.*\(\d+\)/

## TEST: Mixed stdout and stderr
puts "Normal output"
$stderr.puts "Error output"
#=1> "Normal"
#=2> "Error"

## TEST: Variable interpolation in output
name = "Ruby"
puts "Hello, #{name}!"
#=1> "Hello, Ruby!"

## TEST: Empty output expectations (should fail intentionally for testing)
# Note: These are intentionally commented to avoid test failures
# puts "some output"
##=1> "different output"  # Would fail
##=2> "no stderr here"   # Would fail
