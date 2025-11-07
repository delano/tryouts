# try/core/single_hash_comments_try.rb
#
# frozen_string_literal: true

# Setup with single hash comments should not break parsing
require_relative '../../lib/tryouts'

# This is a single hash comment in setup
# Another single hash comment
@variable = 'setup_value'

## TEST: Single hash comments in setup don't interfere with test parsing
@variable
#=> 'setup_value'

## TEST: Multiple single hash comments work correctly
result = 'test_value'
#Single hash comment within test
result
#=> 'test_value'
