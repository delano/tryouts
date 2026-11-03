# try/core/parser_warnings_try.rb
#
# frozen_string_literal: true

# The parser warns about comments that parse but probably do not mean what
# the author intended, and names the line it means.

require 'tempfile'
require_relative '../../lib/tryouts'

def parse_tryouts(source, **options)
  file = Tempfile.new(['warnings', '_try.rb'])
  file.write(source)
  file.flush
  Tryouts::StatementParser.new(file.path, options).parse
ensure
  file&.close!
end

def warning_types(source)
  parse_tryouts(source).warnings.map { |w| [w.type, w.line_number] }
end

## TEST: An expectation inside a statement body is reported, not dropped silently
warning_types(<<~'RUBY')
  ## indented
  if true
    1 + 1
    #=> 2
  end
  #=> 2
RUBY
#=> [[:nested_expectation, 4]]

## TEST: #==> true tests the literal, not the result
warning_types(<<~'RUBY')
  ## vacuous
  [].empty?
  #==> true
RUBY
#=> [[:vacuous_expectation, 3]]

## TEST: Text after #=*> is ignored, and said so
warning_types(<<~'RUBY')
  ## non-nil
  'value'
  #=*> result.length > 3
RUBY
#=> [[:ignored_expectation_text, 3]]

## TEST: An expectation with nothing above it is reported
warning_types(<<~'RUBY')
  #=> 1
  ## first
  1
  #=> 1
RUBY
#=> [[:expectation_without_subject, 1]]

## TEST: A mistyped operator is a warning and an expectation that fails
testrun = parse_tryouts(<<~'RUBY')
  ## typo
  1 + 1
  #=INVALID> 2
RUBY
[testrun.warnings.map(&:type), testrun.test_cases.first.expectations.map(&:type)]
#=> [[:malformed_expectation], [:malformed]]

## TEST: Prose after code is not mistaken for a malformed expectation
warning_types(<<~'RUBY')
  ## prose
  limit = 3 # > 2 is fine here
  limit
  #=> 3
RUBY
#=> []

## TEST: Strict mode names the statement an unnamed expectation attached to
begin
  parse_tryouts(<<~'RUBY', strict: true)
    @registry = []
    @registry << :a
    @registry.size
    #=> 1
  RUBY
rescue Tryouts::TryoutSyntaxError => ex
  ex.message
end
#=~> /asserts on the value of lines 1-3 \(3 statements\), so this test has swallowed the whole prologue/

## TEST: Each expectation knows its own line
testrun = parse_tryouts(<<~'RUBY')
  ## lines
  'abc'
  #=> 'abc'
  #=:> String
RUBY
testrun.test_cases.first.expectations.map(&:line)
#=> [2, 3]

## A mistyped operator that starts like a real one still fails
testrun = parse_tryouts(<<~'RUBY')
  ## raises on nil
  nil.upcase
  #=!!> NoMethodError

  ## is a string
  42
  #=::> String

  ## prints
  puts 'a'
  #=1x> "a"

  ## doubled arrow
  1
  #=>> 1
RUBY
testrun.test_cases.map { |tc| tc.expectations.map(&:type) }
#=> [[:malformed], [:malformed], [:malformed], [:malformed]]
#==> testrun.warnings.map(&:line_number) == [3, 7, 11, 15]

## An expectation behind a description marker fails and says to use one '#'
testrun = parse_tryouts(<<~'RUBY')
  ## list is empty
  list = [1, 2, 3]
  list.empty?
  ##=> true
RUBY
warning = testrun.warnings.first
[warning.type, warning.line_number, testrun.test_cases.first.expectations.map(&:type)]
#=> [:malformed_expectation, 4, [:malformed]]
#==> warning.suggestion.include?("Write '#=>' to assert")

## An expectation commented out with '# #=>' is a plain comment
testrun = parse_tryouts(<<~'RUBY')
  ## skipped
  'foo'
  #=> 'foo'
  # #=> 'not checked'
RUBY
[testrun.warnings, testrun.test_cases.first.expectations.map(&:content)]
#=> [[], ["'foo'"]]

## Prose with '=' and '>' in it is not a mistyped operator
warning_types(<<~'RUBY')
  # = Section =
  # =~ matches, => returns, a = b > c
  ## prose
  limit = 3 # > 2 is fine here
  limit
  #=> 3
RUBY
#=> []
