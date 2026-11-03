# try/core/fresh_context_try.rb
#
# frozen_string_literal: true

# Fresh context (--no-shared-context) gives every test its own object and
# binding: the setup runs again before each test, every interlude above the
# test runs after it, and the teardown runs after each test. Nothing one test
# does is visible to any other. Shared context runs the file as one script.

require 'stringio'
require 'tempfile'
require_relative '../../lib/tryouts'

def statuses_in_context(source, shared:)
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

# The first two words of each verbose console line that announces a
# section, a test or a result, in order.
def announcements_in_context(source, shared:)
  file = Tempfile.new(['context', '_try.rb'])
  file.write(source)
  file.flush

  console = StringIO.new
  output  = Tryouts::CLI::FormatterFactory.create_output_manager(verbose: true, stdout: console, stderr: console)
  testrun = Tryouts::StatementParser.new(file.path).parse
  Tryouts::TestBatch.new(testrun, shared_context: shared, output_manager: output).run
  lines = console.string.lines.map { |line| line.gsub(/\e\[[\d;]*m/, '').strip }
  lines.grep(/\A(Executing|Test \d|PASSED|setup says|teardown says)/).map { |line| line[/\A\S+ \S+/] }
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

announced = <<~'RUBY'
  puts 'setup says hi'

  ## first test
  1
  #=> 1

  ## second test
  2
  #=> 2

  puts 'teardown says bye'
RUBY

## TEST: Fresh context isolates every test, including mutable setup state
$teardowns = 0
statuses_in_context(fixture, shared: false)
#=> [:passed, :passed, :passed]

## TEST: Fresh context runs the teardown after every test
$teardowns = 0
statuses_in_context(fixture, shared: false)
$teardowns
#=> 3

## TEST: Shared context runs the same file as one script
$teardowns = 0
statuses_in_context(fixture, shared: true)
#=> [:passed, :failed, :failed]

## TEST: Shared context runs the teardown once, at the end
$teardowns = 0
statuses_in_context(fixture, shared: true)
$teardowns
#=> 1

## TEST: Fresh context announces the setup before the first test and the teardown after the last
announcements_in_context(announced, shared: false)
#=> ['Executing global', 'setup says', 'Test 1/2:', 'PASSED @', 'Test 2/2:', 'PASSED @', 'Executing teardown', 'teardown says']

## TEST: Both contexts announce sections and tests in the same order
announcements_in_context(announced, shared: false)
#=> announcements_in_context(announced, shared: true)

$teardowns = nil
