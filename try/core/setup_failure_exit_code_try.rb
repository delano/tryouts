# try/core/setup_failure_exit_code_try.rb
#
# frozen_string_literal: true

# Test that setup failures return non-zero exit codes
# This test verifies the fix for issue where setup failures returned 0 instead of proper error codes

require_relative '../../lib/tryouts'

## Test that setup failures are properly tracked in regular mode
test_file_content = <<~RUBY
  # Setup that will fail
  require 'nonexistent_library'

  ## Simple test
  1 + 1
  #=> 2
RUBY

File.write('temp_setup_fail.rb', test_file_content)
cli = Tryouts::CLI.new
exit_code = cli.run(['temp_setup_fail.rb'])
File.delete('temp_setup_fail.rb')
exit_code
#=> 1

## Test that setup failures return proper exit codes in agent mode
test_file_content = <<~RUBY
  # Setup that will fail
  require 'another_nonexistent_library'

  ## Simple test
  2 + 2
  #=> 4
RUBY

File.write('temp_setup_fail_agent.rb', test_file_content)
cli = Tryouts::CLI.new
exit_code = cli.run(['temp_setup_fail_agent.rb'], agent: true)
File.delete('temp_setup_fail_agent.rb')
exit_code
#=> 1

## Test that setup failures return proper exit codes in agent critical mode
test_file_content = <<~RUBY
  # Setup that will fail
  require 'yet_another_nonexistent_library'

  ## Simple test
  3 + 3
  #=> 6
RUBY

File.write('temp_setup_fail_critical.rb', test_file_content)
cli = Tryouts::CLI.new
exit_code = cli.run(['temp_setup_fail_critical.rb'], agent: true, agent_focus: :critical)
File.delete('temp_setup_fail_critical.rb')
exit_code
#=> 1

## Test that successful tests still return 0
test_file_content = <<~RUBY
  ## Simple working test
  1 + 1
  #=> 2
RUBY

File.write('temp_success.rb', test_file_content)
cli = Tryouts::CLI.new
exit_code = cli.run(['temp_success.rb'], agent: true)
File.delete('temp_success.rb')
exit_code
#=> 0
