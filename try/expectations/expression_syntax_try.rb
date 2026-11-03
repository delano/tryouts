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
#=> [[:failed, 'EXPECTED: fixture.rb:3: syntax error in expectation `1 +`: unexpected end-of-input; expected an expression after the operator'], [:passed, '2']]

## A stray brace is the user's, not the wrapper's
expression_failures(<<~'RUBY')
  ## a hash
  { id: 1 }
  #=> }
RUBY
#=> [[:failed, "EXPECTED: fixture.rb:3: syntax error in expectation `}`: unexpected '}', ignoring it"]]

## An expression cannot close the wrapper and start code of its own
expression_failures(<<~'RUBY')
  ## one
  1
  #=> 1 }; -> { 2
RUBY
#=> [[:failed, "EXPECTED: fixture.rb:3: syntax error in expectation `1 }; -> { 2`: unexpected '}', expecting end-of-input"]]

## __END__ in an expression is a syntax error at the expectation's line
expression_failures(<<~'RUBY')
  ## one
  1
  #=> __END__
RUBY
#=> [[:failed, 'EXPECTED: fixture.rb:3: syntax error in expectation `__END__`: __END__ cannot appear in an expectation']]
