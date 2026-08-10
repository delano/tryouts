# try/core/v4_capabilities_demo_try.rb
#
# frozen_string_literal: true

# Demonstrates parsing and execution behavior new in v4. Each case here
# either crashed the v3 parser, silently corrupted the file, or produced
# wrong results under v3's per-block instance_eval execution.

=begin
Block comments are now parsed as a single comment span. In v3 the interior
lines of this block leaked back into the token stream as code, and a line
shaped like an expectation marker, such as the one below, was picked up as
a real expectation and attached to the nearest test case.
#=> "this line is inert"
=end

## TEST: local variables persist across test cases
# v3 evaluated each block with a fresh instance_eval, so locals vanished
# between cases and only instance variables survived. v4 reuses one Binding.
inventory = { apples: 3, pears: 5 }
inventory[:apples]
#=> 3

## TEST: the local from the previous test is still alive
inventory[:pears] += 1
inventory
#=> { apples: 3, pears: 6 }

## TEST: expectation-shaped comments inside multi-line literals are inert
# In v3 a column-0 comment inside an unclosed literal was classified by
# shape alone, so the "#=> 999" below was hoisted out of the array and
# treated as this test's expectation (GitHub issue #3). v4 checks the AST
# and knows these lines sit strictly inside one statement.
prices = [
  100,
  # regular note about the middle element
  200,
  #=> 999
  300,
]
prices.sum
#=> 600

## TEST: expectation types evaluate over code that uses shared locals
# Evaluation semantics are unchanged from v3, and expectation expressions
# still see only `result` (not test-body locals). The v4 win is that the
# test code itself can build on locals from earlier cases.
receipt = "total: #{prices.sum} cents for #{inventory.size} kinds"
receipt
#=:> String
#=~> /total: 600 cents/
#==> result.include?("kinds")
#=/=> result.empty?

## TEST: exception expectations still isolate the failure
# The raise happens in the shared Binding but does not poison later access
# to the accumulated state.
raise ArgumentError, "prices already summed: #{prices.sum}" if prices.sum == 600
#=!> error.is_a?(ArgumentError)
#=!> error.message.include?("600")

## TEST: state survives the raising test case
[inventory[:pears], prices.length]
#=> [6, 3]
