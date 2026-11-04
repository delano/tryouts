# try/core/magic_comments_try.rb
#
# frozen_string_literal: true

# Magic comments at the top of a tryouts file apply to the whole file, as
# they do when Ruby runs it as a script: setup, tests, interludes, teardown
# and expectation expressions.

require 'tempfile'
require_relative '../../lib/tryouts'

def run_magic_fixture(source)
  file = Tempfile.new(['magic', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: true)
  batch.run
  [testrun, batch.results]
ensure
  file&.close!
end

fixture = <<~'RUBY'
  # frozen_string_literal: true

  $magic_frozen = { setup: 'setup'.frozen? }

  ## a test's string literals are frozen
  'test'.frozen?
  #=> true
  #==> 'expectation'.frozen?

  $magic_frozen[:interlude] = 'interlude'.frozen?

  ## an error keeps its own line
  'name' << '!'
  #=> 'name!'

  $magic_frozen[:teardown] = 'teardown'.frozen?
RUBY

testrun, results = run_magic_fixture(fixture)

## The parser records the file's leading magic comments
testrun.magic_comments
#=> ['# frozen_string_literal: true']

## The first test passes, its expectation literal frozen too
results.first.status
#=> :passed

## Setup, interlude and teardown literals are frozen
$magic_frozen
#=> { setup: true, interlude: true, teardown: true }

## Mutating a literal raises FrozenError at the line that did it
error = results.last.error
[error.class, results.last.failure_line + 1]
#=> [FrozenError, 13]

## Comments further down the file are not magic comments
_, plain_results = run_magic_fixture(<<~'RUBY')
  x = 1
  # frozen_string_literal: true

  ## literals are not frozen
  'plain'.frozen?
  #=> false
RUBY
plain_results.map(&:status)
#=> [:passed]

$magic_frozen = nil
