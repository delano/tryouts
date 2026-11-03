# try/expectations/operator_semantics_try.rb
#
# frozen_string_literal: true

# Each expectation operator does one thing, and `result` always means the
# value of the statement under test.

require 'tempfile'
require_relative '../../lib/tryouts'

def run_tryouts(source)
  file = Tempfile.new(['operators', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: true)
  batch.run
  batch.results.map(&:status)
ensure
  file&.close!
end

## TEST: #=<> with a Regexp means "must not match"
"hello123"
#=<> /\A\d+\z/

## TEST: #=<> with a predicate means "must not hold"
[1, 2, 3]
#=<> result.include?(4)

## TEST: #=<> with a value means "must not equal"
1 + 1
#=<> 3

## TEST: #=<> fails when the negated thing holds
run_tryouts(<<~'RUBY')
  ## matches
  "123"
  #=<> /\d+/

  ## includes
  [1, 2, 4]
  #=<> result.include?(4)

  ## equals
  2
  #=<> 2
RUBY
#=> [:failed, :failed, :failed]

## TEST: #=!> accepts a module the exception includes
module Retryable; end
class FlakyError < StandardError
  include Retryable
end
raise FlakyError
#=!> Retryable

## TEST: #=!> runs the test code exactly once when nothing is raised
statuses = run_tryouts(<<~'RUBY')
  $operator_calls = 0

  ## does not raise
  $operator_calls += 1
  #=!> StandardError
RUBY
[statuses, $operator_calls]
#=> [[:failed], 1]

## TEST: #=%> keeps result as the value and exposes elapsed_ms
[1, 2, 3]
#=%> 50
#==> result == [1, 2, 3]

## TEST: #=%> limits must be numbers
run_tryouts(<<~'RUBY')
  ## array limit
  [1, 2, 3]
  #=%> result * 2
RUBY
#=> [:failed]

## TEST: #=:> resolves constants the test defined itself
class LocalWidget; end
LocalWidget.new
#=:> LocalWidget

$operator_calls = nil
