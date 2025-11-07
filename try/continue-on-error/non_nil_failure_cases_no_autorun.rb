# try/continue-on-error/non_nil_failure_cases_no_autorun.rb
#
# frozen_string_literal: true

# Tests for non-nil expectation failures (intentional failures for testing)

puts 'Testing non-nil expectation failure cases...'

## TEST 1: Nil should fail
nil
#=*>

puts 'Failure case tests completed'
