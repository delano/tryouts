# try/debug/setup_exit_handling_try.rb
#
# frozen_string_literal: true

# Test that setup handles SystemExit gracefully

# Setup calls exit - should be caught and reported
puts "Setup with exit"
exit 0

## This test should never run
1 + 1
#=> 2
