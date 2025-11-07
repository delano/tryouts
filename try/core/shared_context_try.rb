# try/core/shared_context_try.rb
#
# frozen_string_literal: true

# Test demonstrating shared context behavior with instance variables
# In shared context mode (default), instance variables persist across all test cases
# This test validates the core behavior of Tryouts' execution context

## Test 1: Set instance variable in test case
@shared_var = "test1_value"
@shared_var
#=> "test1_value"

## Test 2: Access instance variable from previous test
@shared_var
#=> "test1_value"

## Test 3: Modify instance variable in test case
@shared_var = "test3_value"
@shared_var
#=> "test3_value"

## Test 4: Confirm modification persists
@shared_var
#=> "test3_value"

## Test 5: Set new instance variable
@another_var = 42
@another_var
#=> 42

## Test 6: Both instance variables available
[@shared_var, @another_var]
#=> ["test3_value", 42]

## Test 7: Instance variables persist even with local variables
local_var = "local"
@instance_var = "instance"
[local_var, @instance_var]
#=> ["local", "instance"]

## Test 8: Previous test's local variable not available, but instance variable is
@instance_var
#=> "instance"

## Test 9: Instance variables survive across different types of expectations
@counter = 0
@counter += 1
@counter
#==> @counter > 0
#=> 1

## Test 10: Shared context enables stateful testing patterns
@items = []
@items << "first_item"
@items.length
#=> 1

## Test 11: State continues to accumulate
@items << "second_item"
@items
#=> ["first_item", "second_item"]

## Test 12: Complex objects persist their mutations
@config = { debug: false, retries: 3 }
@config[:debug] = true
@config[:retries] += 2
@config
#=> { debug: true, retries: 5 }
