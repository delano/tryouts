# try/debug/parser_boundary_regression_try.rb
# Regression tests for parser section boundary detection
# These tests verify that both parsers handle identical boundary cases correctly

# Minimal reproduction of the boundary bug
puts "Setup line 1"
@critical_var = "critical_value"

## This comment should NOT terminate setup (bug reproduction)
## Multiple lines that look like test descriptions
## but are actually just comments in setup

@another_critical_var = "also_critical"
puts "Setup complete"

## TEST: Critical setup variables should be available
# This is the actual first test
@critical_var
#=> "critical_value"

## TEST: Variables defined after confusing comments should work
@another_critical_var
#=> "also_critical"

## TEST: Verify both parsers behave identically
# This tests parser consistency
[@critical_var, @another_critical_var].compact.length
#=> 2

## TEST: Comments that contain test-like words
# Comments in setup had: test, example, demonstrate, should
# But were not actual test descriptions
"parser_consistency_check"
#=> "parser_consistency_check"

# Teardown
puts "Regression test complete"
