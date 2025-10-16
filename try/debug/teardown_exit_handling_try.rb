# try/debug/teardown_exit_handling_try.rb
# Test that teardown handles SystemExit gracefully

## Test runs normally
1 + 1
#=> 2

## Another test
2 + 2
#=> 4

# Teardown calls exit - should be caught, tests should still pass
puts "Teardown with exit"
exit 0
