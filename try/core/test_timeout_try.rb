# try/core/test_timeout_try.rb
#
# frozen_string_literal: true

# A test that runs past the framework's deadline is an error. A timeout the
# code under test raises itself is an ordinary exception: it keeps its class
# and message, and #=!> can expect it.

require 'net/http'
require 'tempfile'
require 'timeout'
require_relative '../../lib/tryouts'

def run_with_deadline(source, seconds)
  file = Tempfile.new(['deadline', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: true, test_timeout: seconds)
  batch.run
  batch.results
ensure
  file&.close!
end

## A library timeout raised by the code under test keeps its class and message
results = run_with_deadline(<<~'RUBY', 30)
  ## connects
  raise Net::OpenTimeout, 'connect to example.test timed out'
  #=> :connected
RUBY
[results.first.status, results.first.error.class, results.first.error.message]
#=> [:error, Net::OpenTimeout, 'connect to example.test timed out']

## A Timeout.timeout of the code's own keeps its message
results = run_with_deadline(<<~'RUBY', 30)
  ## waits for the queue
  Timeout.timeout(0.01, Timeout::Error, 'queue stayed empty') { sleep 1 }
  #=> :dequeued
RUBY
results.first.error.message
#=> 'queue stayed empty'

## An unexpected Timeout::Error is reported as itself, at its own line
results = run_with_deadline(<<~'RUBY', 30)
  ## fetches the page
  Timeout.timeout(0.01) { sleep 1 }
  #=> :fetched
RUBY
[results.first.error.class, results.first.failure_line + 1]
#=> [Timeout::Error, 2]

## A test that outlives the deadline is an error, even one expecting StandardError
results = run_with_deadline(<<~'RUBY', 0.05)
  ## slow and forgiving
  begin
    sleep 1
  rescue StandardError
    :rescued
  end
  #=!> StandardError
RUBY
[results.first.status, results.first.error.message]
#=> [:error, 'Test execution timeout (0.05s)']
