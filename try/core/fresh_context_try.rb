# try/core/fresh_context_try.rb
#
# frozen_string_literal: true

# Test demonstrating fresh context behavior with instance variables
# In fresh context mode (--no-shared-context), each test case gets a new execution context
# This test validates the isolation behavior of Tryouts' fresh context execution
#
# IMPORTANT: This test is designed to PASS in fresh context mode and FAIL in shared context mode
# Run with: try --no-shared-context try/core/fresh_context_try.rb
#
# To see the difference in behavior:
# Shared context:  try try/core/fresh_context_try.rb (will have failures)
# Fresh context:   try --no-shared-context try/core/fresh_context_try.rb (will pass)

## Test 1: Set instance variable in test case
@isolated_var = "test1_value"
@isolated_var
#=> "test1_value"

## Test 2: Previous test's instance variable not available (fresh context)
# This test should pass in fresh context mode because @isolated_var is nil
@isolated_var.nil?
#==> true

## Test 3: Set same variable name with different value
@isolated_var = "test3_value"
@isolated_var
#=> "test3_value"

## Test 4: Variable from test 3 not available (fresh context)
@isolated_var.nil?
#==> true

## Test 5: Each test starts with clean slate
@counter = 1
@counter
#=> 1

## Test 6: Counter not incremented from previous test
@counter = 1
@counter
#=> 1

## Test 7: Multiple instance variables don't accumulate
@var_a = "a"
@var_b = "b"
[@var_a, @var_b]
#=> ["a", "b"]

## Test 8: Previous test's multiple variables not available
[@var_a, @var_b].all?(&:nil?)
#==> true

## Test 9: Complex objects don't persist
@items = ["item1", "item2"]
@items.length
#=> 2

## Test 10: Array from previous test not available
@items.nil?
#==> true

## Test 11: Hash modifications don't carry over
@config = { setting: "value" }
@config[:setting]
#=> "value"

## Test 12: Config from previous test not available
@config.nil?
#==> true

## Test 13: Fresh context enables truly independent tests
@test_state = "independent"
@test_state
#=> "independent"

## Test 14: Final confirmation of isolation
@test_state.nil?
#==> true
