# try/core/fails_mode_try.rb
# Tests for fails mode functionality

# This should pass
result1 = 1 + 1
#=> 2

# This should fail
result2 = 2 + 2
#=<> 5

# This should pass
result3 = 3 * 3
#=> 9

# This should fail
result4 = 4 * 4
#=<> 20
