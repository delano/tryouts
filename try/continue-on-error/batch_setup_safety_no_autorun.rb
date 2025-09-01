# try/core/test_batch_setup_safety_try.rb
#
# Tests for extenuating circumstances

require_relative '../../lib/tryouts'

test_file = 'foo/bar/setup_baz_try.rb'
Tryouts::LegacyParser.new(test_file)

## TEST: We never get to this testcase b/c setup fails
raise SystemExit
#=<> nil

puts <<MESSAGE
This teardown is never reached. If you can see this message it means that
even though the setup failed tryouts continued to run the batch erroneously.
MESSAGE
