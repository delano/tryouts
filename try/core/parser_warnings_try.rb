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

## An expectation below a new description does not attach to the test above
testrun = parse_tryouts(<<~'RUBY')
  ## counts items
  [1, 2, 3].size
  #=> 3

  ## empty list has no items
  #=> 0
RUBY
expectations = testrun.test_cases.map { |tc| tc.expectations.map(&:content) }
[expectations, testrun.warnings.map { |w| [w.type, w.line_number] }]
#=> [[["3"], ["#=> 0"]], [[:expectation_without_subject, 6]]]
#==> testrun.warnings.first.message.include?('the description at line 5')

## That description names only the detached test; the code below it joins the test the description above names
testrun = parse_tryouts(<<~'RUBY')
  ## first
  total = 1
  ## second
  #=> 1
  total += 1
  #=> 2
RUBY
testrun.test_cases.map { |tc| [tc.description, tc.code] }
#=> [["first", "total = 1\n## second\n#=> 1\ntotal += 1"], ["second", ""]]

## With no description above to take that code, it is an unnamed test, which strict mode rejects
parse_tryouts(<<~'RUBY', strict: true)
  total = 1
  ## second
  #=> 1
  total += 1
  #=> 2
RUBY
#=!> Tryouts::TryoutSyntaxError
#=~> /without explicit description at line 1/

## A mistyped operator with a space inside it, or written backwards, still fails
testrun = parse_tryouts(<<~'RUBY')
  ## negation
  [1, 2, 3].size
  #<=> 3

  ## arrow
  [1, 2].size
  #>= 5

  ## spaced equals
  'abc'
  #= = > 'xyz'

  ## spaced pipe
  puts 'hello'
  #=1 2> 'zzz'

  ## spaced arrow
  1
  #=1 > 1
RUBY
testrun.test_cases.map { |tc| tc.expectations.map(&:type) }
#=> [[:malformed], [:malformed], [:malformed], [:malformed], [:malformed]]
#==> testrun.warnings.map { |w| w.message[/'(.*)'/, 1] } == ['<=>', '>=', '= = >', '=1 2>', '=1 >']

## Prose that starts with an operator stays a plain comment
warning_types(<<~'RUBY')
  # = Title > Subtitle
  # <=> is the spaceship operator
  # >= 2 items is plenty
  # = 3 apples
  ## prose
  [1, 2].size
  #=> 2
RUBY
#=> []

## An expectation behind three hashes or with a spaced operator is not a description
testrun = parse_tryouts(<<~'RUBY')
  ## triple hash
  [1, 2, 3].first
  ###=> 9

  ## spaced operator
  [1, 2, 3].max
  ## = > 8
RUBY
[testrun.test_cases.map(&:description), testrun.test_cases.map { |tc| tc.expectations.map(&:type) }]
#=> [["triple hash", "spaced operator"], [[:malformed], [:malformed]]]
#==> testrun.warnings.map { |w| w.message[/'(.*)'/, 1] } == ['###=>', '## = >']

## A bare '##' line is a plain comment, not an empty description
testrun = parse_tryouts(<<~'RUBY', strict: true)
  ## adds numbers

  ##
  1 + 1
  #=> 2
RUBY
[testrun.test_cases.map(&:description), testrun.warnings]
#=> [["adds numbers"], []]

## An expectation under a bare '##' line still asserts on the statement above it
testrun = parse_tryouts(<<~'RUBY')
  ## first
  total = 1
  ##
  #=> 1
RUBY
[testrun.test_cases.map { |tc| [tc.description, tc.code] }, testrun.warnings]
#=> [[["first", "total = 1"]], []]

## A doubled or mistyped expectation inside a method or block body is reported like '#=>' there
warning_types(<<~'RUBY')
  def total(prices)
    sum = prices.sum
    ##=> 2.0
    sum
  end

  ## maps each price
  [1.25, 0.75].map do |price|
    price * 2
    #=X> 2.5
  end
  #=> [2.5, 1.5]
RUBY
#=> [[:nested_expectation, 3], [:nested_expectation, 10]]

## A spaced '# =>' doc comment inside a method body is not reported
warning_types(<<~'RUBY')
  def total(prices)
    prices.sum # => 2.0
    # => 2.0 for the default cart
  end

  ## sums prices
  total([1.25, 0.75])
  #=> 2.0
RUBY
#=> []

## A spaced comparison in a comment is prose, such as a version requirement in the setup
testrun = parse_tryouts(<<~'RUBY')
  require 'json'
  # >= 2.0
  # <=> compares

  ## parses an array
  JSON.parse('[1]')
  #=> [1]
RUBY
[testrun.test_cases.map(&:description), testrun.warnings.map(&:type)]
#=> [["parses an array"], []]

## A bare '##' spacer between description lines does not split the description
testrun = parse_tryouts(<<~'RUBY', strict: true)
  ## Sums two numbers
  ##
  ## and the result is an Integer
  1 + 1
  #=> 2
RUBY
[testrun.test_cases.map(&:description), testrun.test_cases.first.line_range.first]
#=> [["Sums two numbers and the result is an Integer"], 0]

## A spacer also joins the description of an expectation with no statement above it
testrun = parse_tryouts(<<~'RUBY')
  ## counts items
  [1, 2, 3].size
  #=> 3

  ## an empty list
  ##
  ## has no items
  #=> 0
RUBY
testrun.test_cases.map(&:description)
#=> ["counts items", "an empty list has no items"]
