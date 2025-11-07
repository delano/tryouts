# try/core/class_functionality_try.rb
#
# frozen_string_literal: true

# Tests for core Tryouts class functionality
require_relative '../test_helper'

## TEST: TRYOUTS_LIB_HOME constant is defined
defined?(TRYOUTS_LIB_HOME)
#=> "constant"

## TEST: TRYOUTS_LIB_HOME points to lib directory
TRYOUTS_LIB_HOME.end_with?('lib')
#=> true

## TEST: Tryouts class has expected attributes
Tryouts.respond_to?(:container)
#=> true

## TEST: Tryouts responds to quiet attribute
Tryouts.respond_to?(:quiet)
#=> true

## TEST: Tryouts responds to noisy attribute
Tryouts.respond_to?(:noisy)
#=> true

## TEST: Tryouts responds to fails attribute
Tryouts.respond_to?(:fails)
#=> true

## TEST: Tryouts responds to debug? method
Tryouts.respond_to?(:debug?)
#=> true

## TEST: Tryouts responds to cases attribute
Tryouts.respond_to?(:cases)
#=> true

## TEST: Tryouts responds to testcase_io attribute
Tryouts.respond_to?(:testcase_io)
#=> true

## TEST: Default values are set correctly. We check for either boolean value
## b/c Tryouts.debug? returns the actual value not a mock. If the test suite
# is run with --debug, this would fail otherwise.
Tryouts
#=|> _.debug?

## TEST: Quiet mode defaults to false
Tryouts.quiet
#=> false

## TEST: Noisy mode defaults to false
Tryouts.noisy
#=> false

## TEST: Fails mode defaults to false
Tryouts.fails
#=> false

## TEST: Cases array defaults to empty
Tryouts.cases
#=> []

## TEST: Testcase_io defaults to StringIO
Tryouts.testcase_io.class
#=> StringIO

## TEST: Container is a class
Tryouts.container.class
#=> Class

## TEST: Debug mode toggle
Tryouts.debug = true
Tryouts.debug?
#=> true

## TEST: Debug mode can be disabled
Tryouts.debug = false
Tryouts.debug?
#=> false

## TEST: Quiet mode toggle
Tryouts.quiet = true
Tryouts.quiet
#=> true

## TEST: Quiet mode can be disabled
Tryouts.quiet = false
Tryouts.quiet
#=> false

## TEST: Noisy mode toggle
Tryouts.noisy = true
Tryouts.noisy
#=> true

## TEST: Noisy mode can be disabled
Tryouts.noisy = false
Tryouts.noisy
#=> false

## TEST: Fails mode toggle
Tryouts.fails = true
Tryouts.fails
#=> true

## TEST: Fails mode can be disabled
Tryouts.fails = false
Tryouts.fails
#=> false

## TEST: update_load_path modifies $LOAD_PATH
original_load_path = $LOAD_PATH.dup
Tryouts.update_load_path('./lib')
$LOAD_PATH.length >= original_load_path.length
#=> true

## TEST: trace method outputs when debug is enabled
Tryouts.debug = true
captured_output = nil
begin
  old_stderr = $stderr
  $stderr = StringIO.new
  Tryouts.trace("test message")
  captured_output = $stderr.string
ensure
  $stderr = old_stderr
end
captured_output.include?("TRACE") && captured_output.include?("test message")
#=> true

## TEST: trace method silent when debug is disabled
Tryouts.debug = false
captured_output = nil
begin
  old_stderr = $stderr
  $stderr = StringIO.new
  Tryouts.trace("test message")
  captured_output = $stderr.string
ensure
  $stderr = old_stderr
end
captured_output.empty?
#=> true

## TEST: trace method with indentation
Tryouts.debug = true
captured_output = nil
begin
  old_stderr = $stderr
  $stderr = StringIO.new
  Tryouts.trace("indented message", indent: 2)
  captured_output = $stderr.string
ensure
  $stderr = old_stderr
end
captured_output.start_with?("    ")
#=> true

## TEST: Coverage loading status matches environment
# SimpleCov should be loaded when COVERAGE env var is set, not loaded otherwise
load_result = begin
  defined?(SimpleCov) ? "loaded" : "not_loaded"
rescue
  "not_available"
end

expected_result = ENV['COVERAGE'] ? "loaded" : "not_loaded"
load_result == expected_result
#=> true

Tryouts.debug = false
