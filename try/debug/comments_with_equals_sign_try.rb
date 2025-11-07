# try/debug/comments_with_equals_sign_try.rb
#
# frozen_string_literal: true

require_relative '../test_helper'

# This is parse of the batch setup = 1
@ret = Bone.new('atoken2', 'smurf', 1001)

# Tests for the non-nil expectation syntax (#=*>)
puts 'end of setup'

## Familia::String#increment #=$BOGUS$>
@ret.token
#=> 'atoken2'

## Familia::String#increment #=>
@ret.token
#=> 'atoken2'
