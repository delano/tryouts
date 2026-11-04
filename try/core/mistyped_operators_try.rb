# try/core/mistyped_operators_try.rb
#
# frozen_string_literal: true

# An expectation whose operator lost a character must not turn into a plain
# comment that takes its test with it. A missing '=' fails the test; a
# missing '>' leaves a test with no expectation, which the parser reports.
# A divider of '=' signs is still just a comment.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def run_file(source)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'typos_try.rb')
    File.write(path, source)
    out  = StringIO.new
    code = Tryouts::CLI.new.run([path], stdout: out, stderr: out)
    [code, out.string.gsub(/\e\[[\d;]*m/, '')]
  end
end

def batch_for(source, shared: true)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'typos_try.rb')
    File.write(path, source)
    testrun = Tryouts::StatementParser.new(path, strict: true).parse
    batch   = Tryouts::TestBatch.new(testrun, shared_context: shared)
    batch.run
    batch
  end
end

missing_equals = <<~'RUBY'
  ## parses digits
  Integer('42')
  #=> 42

  ## rejects words
  Integer('twelve')
  #!> ArgumentError

  ## finds the word
  'hello world'
  #~> /world/

  ## is a String
  'hello'.upcase
  #:> String

  ## has a first element
  [3, 1, 2].first
  #*>

  ## sorts quickly
  [3, 1, 2].sort
  #%> 50

  ## is a boolean
  [].empty?
  #|> result

  ## counts three
  [1, 2, 3].size
  #-> 3

  ## is not three
  [1, 2].size
  #!=> 3

  ## does not match
  'hello'
  #~=> /xyz/
RUBY

missing_arrow = <<~'RUBY'
  ## sums the prices
  [1.25, 0.75].sum
  #=> 2.0

  ## finds the word
  'hello world'
  #=~ /world/

  ## counts the words
  'hello world'.split.size
  #=> 2

  ## prints a greeting
  puts 'hi'
  #=1 "hi"
RUBY

divider = <<~'RUBY'
  ## doubles the count
  count = 3
  # =====>
  count * 2
  #=> 6
  # ===========================================>

  ## halves the count
  count / 3
  #=> 1
RUBY

## An operator with its '=' left out fails its test instead of vanishing
batch = batch_for(missing_equals)
batch.results.map { |r| [r.test_case.description, r.status] }
#=> [["parses digits", :passed], ["rejects words", :error], ["finds the word", :failed], ["is a String", :failed], ["has a first element", :failed], ["sorts quickly", :failed], ["is a boolean", :failed], ["counts three", :failed], ["is not three", :failed], ["does not match", :failed]]

## The same tests fail in fresh context
batch = batch_for(missing_equals, shared: false)
batch.results.reject(&:passed?).size
#=> 9

## Each one is reported with the operator as written
batch = batch_for(missing_equals)
batch.testrun.warnings.map { |w| w.message[/'(.*)'/, 1] }
#=> ["!>", "~>", ":>", "*>", "%>", "|>", "->", "!=>", "~=>"]

## A spaced backwards operator before a value fails like '#>= 5' does
batch = batch_for(<<~'RUBY')
  ## at least five items
  [1, 2].size
  # >= 5

  ## no more than one
  [1, 2].size
  #>= 1
RUBY
batch.results.map { |r| [r.test_case.description, r.status] }
#=> [["at least five items", :failed], ["no more than one", :failed]]

## A described test whose operator lost its '>' is reported by name and section, as a warning only
code, output = run_file(missing_arrow)
output.scan(/Test '.*' at line \d+ has no expectation; its code runs as [a-z ]+/)
#=> ["Test 'finds the word' at line 5 has no expectation; its code runs as an interlude", "Test 'prints a greeting' at line 13 has no expectation; its code runs as teardown"]
#==> code.zero?

## The first test in that file is reported as setup when nothing precedes it
batch = batch_for(<<~'RUBY')
  ## loads the prices
  prices = { apple: 1.25 }
  #== { apple: 1.25 }

  ## has one price
  prices.size
  #=> 1
RUBY
batch.testrun.warnings.map(&:message)
#=> ["Test 'loads the prices' at line 1 has no expectation; its code runs as setup"]

## A '##' heading over setup or helper code with no expectation-like comment is not reported
batch = batch_for(<<~'RUBY')
  ## Helpers
  # Used by the tests below
  def double(n) = n * 2

  ## doubles a number
  double(2)
  #=> 4
RUBY
batch.testrun.warnings
#=> []

## A divider of four or more '=' before '>' is a plain comment, even in strict mode
code, output = run_file(divider)
[code, output[/\d+ passed/], output[/Warnings:/]]
#=> [0, "2 passed", nil]

## Three '=' before '>' is still a mistyped operator
batch = batch_for(<<~'RUBY')
  ## triples
  3 * 3
  #===> 9
RUBY
[batch.results.map(&:status), batch.testrun.warnings.map { |w| w.message[/'(.*)'/, 1] }]
#=> [[:failed], ["===>"]]
