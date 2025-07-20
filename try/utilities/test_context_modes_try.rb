# try/utilities/test_context_modes_try.rb
# Tests for fresh vs shared context execution modes

require_relative '../../lib/tryouts'

@test_file = 'try/parsing/basic_syntax_try.rb'
@parser = Tryouts::PrismParser.new(@test_file)

## TEST: Parser can parse test file
testrun = @parser.parse
testrun.test_cases.size > 0
#=> true

## TEST: Fresh context batch can be created
testrun = @parser.parse
batch_fresh = Tryouts::TestBatch.new(testrun, shared_context: false)
batch_fresh.respond_to?(:run)
#=> true

## TEST: Shared context batch can be created
testrun = @parser.parse
batch_shared = Tryouts::TestBatch.new(testrun, shared_context: true)
batch_shared.respond_to?(:run)
#=> true

## TEST: Batch sizes are equal
testrun = @parser.parse
batch_shared = Tryouts::TestBatch.new(testrun, shared_context: true)
batch_fresh = Tryouts::TestBatch.new(testrun, shared_context: false)
batch_fresh.size == batch_shared.size
#=> true

## TEST: Context modes are different
testrun = @parser.parse
batch_shared = Tryouts::TestBatch.new(testrun, shared_context: true)
batch_fresh = Tryouts::TestBatch.new(testrun, shared_context: false)

contextA = batch_fresh.instance_variable_get(:@shared_context)
contextB = batch_shared.instance_variable_get(:@shared_context)

!(contextA.nil? && contextB.nil?) && contextA != contextB
#=> true
