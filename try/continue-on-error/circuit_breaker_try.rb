# try/continue-on-error/circuit_breaker_try.rb
#
# frozen_string_literal: true

# Circuit breaker test - create multiple failing tests to trigger circuit breaker

## TEST: First failure
raise "intentional error 1"
#=<> nil

## TEST: Second failure
raise "intentional error 2"
#=<> nil

## TEST: Third failure
raise "intentional error 3"
#=<> nil

## TEST: Fourth failure
raise "intentional error 4"
#=<> nil

## TEST: Fifth failure
raise "intentional error 5"
#=<> nil

## TEST: Sixth failure
raise "intentional error 6"
#=<> nil

## TEST: Seventh failure
raise "intentional error 7"
#=<> nil

## TEST: Eighth failure
raise "intentional error 8"
#=<> nil

## TEST: Ninth failure
raise "intentional error 9"
#=<> nil

## TEST: Tenth failure - should trigger circuit breaker
raise "intentional error 10"
#=<> nil

## TEST: This should be skipped by circuit breaker
1 + 1
#=> 2

## TEST: This should also be skipped by circuit breaker
"hello world"
#=> "hello world"
