# try/safety/batch_setup_familia_failure_try.rb

require_relative '../test_helper'

# This is parse of the batch setup
@ret = Bone.new('atoken2', 'smurf', 1001)
puts 'end of setup'

## Familia::String#increment
@ret.token
#=> 'atoken2'

## Familia::String#incrementby
@ret.name
#=> 'smurf'

## Familia::String#decrement
@ret.age
#=> 1001

puts 'this is the teardown'
