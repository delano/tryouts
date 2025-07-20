# try/test_helper.rb

# Coverage is handled by the CLI entry point to avoid double initialization

# Require the main library
require_relative '../lib/tryouts'

# Test utilities and common setup
module TestHelper
  def self.silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
