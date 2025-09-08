## Test that setup failures result in proper exit code 1
##
## This regression test replicates the issue where setup failures
## would incorrectly exit with code 0 instead of 1 in agent mode.

# Create a test file that has a setup failure similar to the real-world case
File.write('test_setup_failure_regression.try.rb', <<~TEST_FILE)
  # Setup that fails with a runtime error
  external_identifiers = require('object_identifiers')
  # This will raise a LoadError since object_identifiers doesn't exist

  ## Test case that should not run due to setup failure
  puts 'This test should not execute'
  #=> nil
TEST_FILE

## Run with agent mode and verify exit code is 1 for setup failure
result = system("ruby -I lib exe/try --agent test_setup_failure_regression.try.rb >/dev/null 2>&1")
exit_code = $?.exitstatus
exit_code
#=> 1

## Also test without agent mode to ensure consistency
result = system("ruby -I lib exe/try test_setup_failure_regression.try.rb >/dev/null 2>&1")
exit_code_non_agent = $?.exitstatus
exit_code_non_agent
#=> 1

## Clean up the test file
File.delete('test_setup_failure_regression.try.rb')
true
#=> true
