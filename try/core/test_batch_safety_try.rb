# try/core/test_batch_safety_try.rb
#
# Tests for extenuating circumstances

require_relative '../../lib/tryouts'

test_file = 'foo/bar/setup_baz_try.rb'
Tryouts::PrismParser.new(test_file)

## TEST: Batch does not fail and the following test cases continue
raise SystemExit
#=<> nil

## TEST: Calling exit with a non-zero status code, batch does not fail
## and the following test cases continue
exit 3
#=<> nil

## TEST: Timeout errors are handled gracefully
raise Timeout::Error, 'Intentional timeout error'
#=<> nil

## TEST: SIGHUP is handled gracefully
raise SignalException, 'SIGHUP'
#=<> nil

test_file = 'foo/bar/teardown_baz_try.rb'
Tryouts::PrismParser.new(test_file)
