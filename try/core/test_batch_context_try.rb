# try/core/test_batch_context_try.rb
# Tests for TestBatch with fresh context per test

require_relative '../../lib/tryouts'

@test_file = 'try/core/basic_syntax_try.rb'
@parser = Tryouts::PrismParser.new(@test_file)


## TEST: Parser creates valid testrun
testrun = @parser.parse
testrun.class.name
#=> "Tryouts::Testrun"

## TEST: TestBatch initializes correctly
testrun = @parser.parse
batch = Tryouts::TestBatch.new(testrun)
batch.size > 0
#=> true

## TEST: Fresh context execution completes
testrun = @parser.parse
batch = Tryouts::TestBatch.new(testrun)
success = batch.run
success != nil
#=> true

## TEST: TestBatch reports results correctly
testrun = @parser.parse
batch = Tryouts::TestBatch.new(testrun)
batch.respond_to?(:failed_count)
#=> true
