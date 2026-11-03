# try/core/fresh_context_try.rb
#
# frozen_string_literal: true

# Fresh context (--no-shared-context) gives every test its own object and
# binding: the setup runs again before each test, every interlude above the
# test runs after it, and the teardown runs after each test. Nothing one test
# does is visible to any other. Shared context runs the file as one script.

require 'tempfile'
require_relative '../../lib/tryouts'

def run_tryouts(source, shared:)
  file = Tempfile.new(['context', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: shared)
  batch.run
  batch.results.map(&:status)
ensure
  file&.close!
end

fixture = <<~'RUBY'
  @items = []
  count  = 0

  ## the first test changes a local, an ivar, and a mutable object from setup
  @items << :a
  count += 1
  @items.size
  #=> 1

  @items << :interlude

  ## the second test sees the setup and the interlude above it, nothing else
  [@items, count]
  #=> [[:interlude], 0]

  ## a third test starts from the same state
  [@items, count]
  #=> [[:interlude], 0]

  $teardowns += 1
RUBY

## TEST: Fresh context isolates every test, including mutable setup state
$teardowns = 0
run_tryouts(fixture, shared: false)
#=> [:passed, :passed, :passed]

## TEST: Fresh context runs the teardown after every test
$teardowns = 0
run_tryouts(fixture, shared: false)
$teardowns
#=> 3

## TEST: Shared context runs the same file as one script
$teardowns = 0
run_tryouts(fixture, shared: true)
#=> [:passed, :failed, :failed]

## TEST: Shared context runs the teardown once, at the end
$teardowns = 0
run_tryouts(fixture, shared: true)
$teardowns
#=> 1

$teardowns = nil
