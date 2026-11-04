# Setup that fails with a runtime error
external_identifiers = require('object_identifiers')
# This will raise a LoadError since object_identifiers doesn't exist

## Test case that should not run due to setup failure
puts 'This test should not execute'
#=> nil
