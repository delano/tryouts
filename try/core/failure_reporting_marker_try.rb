# try/core/failure_reporting_marker_try.rb
#
# frozen_string_literal: true

# An expectation that raises while it is evaluated is reported as an
# expectation error. An ordinary expected String that happens to begin
# with the same words is still an ordinary expected value.

require 'tempfile'
require_relative '../../lib/tryouts'

def failure_reasons(source)
  file = Tempfile.new(['marker', '_try.rb'])
  file.write(source)
  file.flush

  testrun   = Tryouts::StatementParser.new(file.path).parse
  batch     = Tryouts::TestBatch.new(testrun, shared_context: true)
  collector = Tryouts::FailureCollector.new
  batch.run
  batch.results.each { |result| collector.add_failure(file.path, result) }
  collector.all_failures.map(&:failure_reason)
ensure
  file&.close!
end

## A status line that begins like the error label is compared as text
failure_reasons(<<~'RUBY')
  ## status line
  "EXPECTED: 4"
  #=> "EXPECTED: 5"
RUBY
#=> ['expected "EXPECTED: 5", got "EXPECTED: 4"']

## An expectation that names something undefined is an expectation error
failure_reasons(<<~'RUBY')
  ## total
  [1, 2].sum
  #=> subtotal
RUBY
#=~> /undefined local variable or method .subtotal/
