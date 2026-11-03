# try/core/single_hash_test_try.rb
#
# frozen_string_literal: true

# A single `#` is always a plain comment, whatever it says. Only `##` names a
# test, and only consecutive `##` lines (no blank line or plain comment
# between them) join into one description.

require 'tempfile'
require_relative '../../lib/tryouts'

def parse_single_hash(source)
  file = Tempfile.new(['single_hash', '_try.rb'])
  file.write(source)
  file.flush
  Tryouts::StatementParser.new(file.path).parse
ensure
  file&.close!
end

testrun = parse_single_hash(<<~'RUBY')
  # This is a setup comment
  setup_value = "setup"

  # This comment shows what happens when a comment reads like a description
  result = 1 + 1
  #=> 2

  ## A description can span
  ## more than one line
  [1, 2, 3].length
  #=> 3
RUBY

## TEST: A single-hash comment never becomes a description
testrun.test_cases.first.description
#=> ''

## TEST: Without a description since the setup, the statements above the expectation are its test
testrun.test_cases.first.code.lines.grep_v(/\A\s*#/).map(&:strip).reject(&:empty?)
#=> ['setup_value = "setup"', 'result = 1 + 1']

## TEST: The unnamed test is reported with the statement it is attached to
testrun.warnings.map(&:type)
#=> [:unnamed_test]

## TEST: Consecutive ## lines join into one description
testrun.test_cases.last.description
#=> 'A description can span more than one line'

## A blank line or a plain comment ends a block of ## lines
headed = parse_tryouts(<<~'RUBY')
  ## Arithmetic

  ## adds two numbers
  1 + 1
  #=> 2

  ## subtract (disabled for now)
  # 3 - 1
  ## multiplies
  2 * 3
  #=> 6
RUBY
headed.test_cases.map { |tc| [tc.description, tc.line_range.first] }
#=> [['adds two numbers', 2], ['multiplies', 8]]
