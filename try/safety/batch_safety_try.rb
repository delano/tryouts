# try/core/test_batch_safety_try.rb
#
# Tests for extenuating circumstances

# NOTE: These tests are expected to show as ERRORS in the output since they
# verify that dangerous exceptions are caught and handled gracefully.
#
# Success is measured by:
# 1. All tests execute (batch doesn't stop)
# 2. Teardown runs successfully
# 3. Framework doesn't crash
# 4. CI workflow is configured with continue-on-error: true for this directory
#
# EXPECTED OUTPUT: 0 passed, 4 errors

require_relative '../../lib/tryouts'

## TEST: Batch does not fail and the following test cases continue
puts 'Example STDOUT Output for an intentionally failing test'
raise SystemExit
#=<> nil

## TEST: Calling exit with a non-zero status code, batch does not fail
## and the following test cases continue
$stderr.puts 'Example STDERR Output for an intentionally failing test'
exit 3
#=<> nil

## TEST: Timeout errors are handled gracefully
raise Timeout::Error, 'Intentional timeout error'
#=<> nil

## TEST: SIGHUP is handled gracefully
raise SignalException, 'SIGHUP'
#=<> nil
