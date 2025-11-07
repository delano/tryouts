# try/continue-on-error/agent_friendly_warnings.try.rb
#
# frozen_string_literal: true

## Test with proper description
result = 1 + 1
#=> 2

# This creates an unnamed test that should trijgger a warning
value = "hello world"
#=> "hello world"

## Another properly described test
calculation = 3 * 4
#=> 12

## TEST: Array length calculation
numbers = [1, 2, 3]
numbers.length
#=> 3
