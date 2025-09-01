# try/core/test_batch_setup_try.rb
# Tests for TestBatch setup execution logic

require_relative '../../lib/tryouts'

@test_file = 'try/core/basic_syntax_try.rb'
@parser = Tryouts::LegacyParser.new(@test_file)
@testrun = @parser.parse

## TEST: Parser successfully parses test file
@testrun.total_tests > 0
#=> true

## TEST: TestBatch can be created
batch = Tryouts::TestBatch.new(@testrun)
batch.respond_to?(:run)
#=> true

## TEST: TestBatch has correct size
batch = Tryouts::TestBatch.new(@testrun)
batch.size == @testrun.total_tests
#=> true

## TEST: TestBatch starts with zero failures
batch = Tryouts::TestBatch.new(@testrun)
batch.failed_count
#=> 0

## TEST: TestBatch can execute successfully
batch = Tryouts::TestBatch.new(@testrun)
success = batch.run
success.is_a?(TrueClass) || success.is_a?(FalseClass)
#=> true
