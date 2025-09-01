# try/core/teardown_handling_try.rb
# Tests for teardown detection functionality

require_relative '../../lib/tryouts'

test_file = 'try/core/basic_syntax_try.rb'
@parser = Tryouts::LegacyParser.new(test_file)

## TEST: Parser can detect teardown in basic syntax file

testrun = @parser.parse
testrun.teardown.empty?
#=> false

## TEST: Test cases are properly parsed
testrun = @parser.parse
testrun.test_cases.size > 0
#=> true

## TEST: Teardown has content
testrun = @parser.parse
testrun.teardown.code.length > 0
#=> true

## TEST: Teardown contains expected content
testrun = @parser.parse
testrun.teardown.code.include?('teardown succeeded')
#=> true
