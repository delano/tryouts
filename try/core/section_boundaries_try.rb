# try/core/section_boundaries_try.rb
#
# frozen_string_literal: true

# Tests for proper section boundary detection - setup, test, teardown

# Setup section with various comment patterns that should NOT create new blocks
puts "Setup starting"
@setup_var = "setup_value"

# Regular comments in setup should be fine
# Multiple line comments
## This comment looks like a test description BUT it's in setup
## and should NOT terminate the setup section prematurely

# More setup code after the confusing comment
@another_var = 42
@complex_data = {
  key: "value",
  nested: { data: [1, 2, 3] }
}

puts "Setup complete with all variables defined"

## TEST: Variables from setup should be available in test
# This is the FIRST real test case
result = @setup_var + "_test"
#=> "setup_value_test"

## TEST: Numeric variables should work
@another_var * 2
#=> 84

## TEST: Complex data structures from setup
@complex_data[:nested][:data].length
#=> 3

## TEST: Ensure setup ran completely
# All setup variables should be defined
[@setup_var, @another_var, @complex_data].all? { |var| !var.nil? }
#==> true

## TEST: Multiple description lines
## should work as expected
## when they actually precede a test
"multi-line test"
#=> "multi-line test"

## TEST: Edge case with similar setup pattern
# This tests that ## comments work in tests too
@test_local = "test_value"
# This comment is inside a test, should be fine
result = @test_local
#=> "test_value"

# Teardown section
puts "Starting teardown"

# Comments in teardown should also work
## This comment is in teardown and should not affect parsing

@cleanup_var = "cleaned"
puts "Teardown complete"
