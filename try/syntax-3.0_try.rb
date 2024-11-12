# @requires active_support
# @version >= 3.0
# @ruby >= 3.0.0
# @at 2024-01-01 12:00
# @timezone UTC

require 'active_support/time'

@count = 0
@frozen_string = "can't change me".freeze

## TEST 1: Basic single-line expectation (baseline)
@count += 1
#=> 1

## TEST 2: Multi-line hash expectation
complex = {
  a: 1,
  b: {
    c: 2,
    d: [3, 4]
  }
}
#=> {
#    a: 1,
#    b: {
#      c: 2,
#      d: [3, 4]
#    }
#    }

## TEST 3: Expected error with message
@frozen_string.upcase!
#!> FrozenError: can't modify frozen string

## TEST 4: Time travel verification
Time.now
#=> 2024-01-01 12:00:00 UTC

## TEST 5: Multiple expectations from same code
result = [1, 2, 3]
#=> [1, 2, 3]  # Full array
#=> 3          # Length via implicit to_s

## TEST 6: Disabled expectations
result.reverse
##=> [3, 2, 1]
#!> TypeError  # This error won't be checked

## TEST 7: Complex multi-line output with status
require 'json'
JSON.pretty_generate({
  status: 'success',
  data: { id: 123 }
})
#=> {
#      "status": "success",
#      "data": {
#        "id": 123
#      }
#    }
#    pass

## TEST 8: Time-sensitive operations
@now = Time.now
@now + 1.day
#=> 2024-01-02 12:00:00 UTC
