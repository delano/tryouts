# try/expectations/expression_syntax_try.rb
#
# frozen_string_literal: true

# An expectation whose expression is not valid Ruby fails its test. The
# message names the expectation's own line and the expression as written.

require 'tempfile'
require_relative '../../lib/tryouts'

def expression_failures(source)
  file = Tempfile.new(['expression', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: true)
  batch.run
  batch.results.map do |result|
    [result.status, result.failed_expected.to_s.sub(file.path, 'fixture.rb')]
  end
ensure
  file&.close!
end

## An incomplete expression is reported at its own line
expression_failures(<<~'RUBY')
  ## sums
  1 + 1
  #=> 1 +

  ## still runs
  2
  #=> 2
RUBY
#=> [[:failed, 'fixture.rb:3: syntax error in expectation `1 +`: expected an expression after the operator'], [:passed, '2']]

## A stray brace is the user's, not the wrapper's
expression_failures(<<~'RUBY')
  ## a hash
  { id: 1 }
  #=> }
RUBY
#=> [[:failed, "fixture.rb:3: syntax error in expectation `}`: unexpected '}', expecting end-of-input"]]

## An expression cannot close the wrapper and start code of its own
expression_failures(<<~'RUBY')
  ## one
  1
  #=> 1 }; -> { 2
RUBY
#=> [[:failed, "fixture.rb:3: syntax error in expectation `1 }; -> { 2`: unexpected '}', expecting end-of-input"]]

## __END__ in an expression is a syntax error at the expectation's line
expression_failures(<<~'RUBY')
  ## one
  1
  #=> __END__
RUBY
#=> [[:failed, 'fixture.rb:3: syntax error in expectation `__END__`: __END__ cannot appear in an expectation']]

## next and break are valid in an expectation, as in any lambda
results = expression_failures(<<~'RUBY')
  ## next gives the value
  1
  #=> next 1

  ## break gives nil
  nil
  #=> break
RUBY
results.map(&:first)
#=> [:passed, :passed]

## Syntax the running Ruby accepts is not rejected
expression_failures(<<~'RUBY')
  ## index assignment with a keyword-style key
  store = {}
  store.size
  #==> (store[key: 1] = :set) == :set
RUBY
#=> [[:passed, 'true']]

## A SyntaxError raised while the expectation runs is the test's error, not the expectation's syntax
results = expression_failures(<<~'RUBY')
  ## evaluates a snippet
  snippet = '1 +'
  #=> eval(snippet)
RUBY
results
#=> [[:error, '']]
