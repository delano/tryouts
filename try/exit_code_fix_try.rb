# lib/tryouts/test_executor.rb

# Test that setup failures result in non-zero exit code


# Create a test file with setup failure
File.write('test_setup_failure.try.rb', "
# Setup that fails
undefined_variable  # This will cause NameError

## Test case
puts 'This should not run'
#=> nil
")

## Run the test with agent mode and check exit code
system("ruby -I lib exe/try --agent test_setup_failure.try.rb >/dev/null 2>&1")
$?.exitstatus
#=> 1

## Clean up
File.delete('test_setup_failure.try.rb')
true
#=> true
