# try/core/test_batch_teardown_safety_try.rb
#
# Tests for extenuating circumstances

require_relative '../../lib/tryouts'

puts <<MESSAGE
We should see this setup message and the testcase in this file should pass.
The teardown should fail because we intentionally caused an error by
reading a non-existent file.
MESSAGE

## TEST: A basic test
1 + 1
#=> 2

test_file = 'foo/bar/setup_baz_try.rb'
Tryouts::LegacyParser.new(test_file)
