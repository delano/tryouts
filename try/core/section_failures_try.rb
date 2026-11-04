# try/core/section_failures_try.rb
#
# frozen_string_literal: true

# A setup or interlude that raises stops its file; a teardown that raises is
# reported and the file completes. Either way the failure is reported with
# its message and recorded as an infrastructure failure, whatever kind of
# exception it is.

require 'stringio'
require 'tempfile'
require_relative '../../lib/tryouts'

def run_sections_fixture(source, shared: true)
  file = Tempfile.new(['sections', '_try.rb'])
  file.write(source)
  file.flush

  console    = StringIO.new
  aggregator = Tryouts::TestResultAggregator.new
  output     = Tryouts::CLI::FormatterFactory.create_output_manager(verbose: true, stdout: console, stderr: console)
  testrun    = Tryouts::StatementParser.new(file.path).parse
  batch      = Tryouts::TestBatch.new(testrun, shared_context: shared, output_manager: output, global_tally: { aggregator: aggregator })
  passed     = batch.run

  {
    passed: passed,
    statuses: batch.results.map(&:status),
    console: console.string,
    infrastructure: aggregator.get_infrastructure_failures.map { |failure| failure[:type] },
  }
end

## A SyntaxError raised by an interlude stops the file and is reported
run = run_sections_fixture(<<~'RUBY')
  ## first test
  1
  #=> 1

  eval('def broken(')

  ## second test
  2
  #=> 2
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [false, [:passed], [:orphan]]
#==> run[:console].include?('Orphan code block failed')

## A LoadError raised by the setup stops the file and is reported
run = run_sections_fixture(<<~'RUBY')
  require 'tryouts_missing_setup_helper'

  ## never runs
  1
  #=> 1
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [false, [], [:setup]]
#==> run[:console].include?('Global setup error: cannot load such file -- tryouts_missing_setup_helper')

## A LoadError raised by a fresh-context teardown keeps the test's result
run = run_sections_fixture(<<~'RUBY', shared: false)
  ## first test
  1
  #=> 1

  require 'tryouts_missing_cleanup_helper'
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [true, [:passed], [:teardown]]
#==> run[:console].include?('Teardown failed: cannot load such file -- tryouts_missing_cleanup_helper')

## A fresh-context setup that fails only on its second run is reported
$connections_opened = 0
run = run_sections_fixture(<<~'RUBY', shared: false)
  $connections_opened += 1
  raise "too many connections (#{$connections_opened})" if $connections_opened > 1

  ## first test
  1
  #=> 1

  ## second test
  2
  #=> 2
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [false, [:passed], [:setup]]
#==> run[:console].include?("Global setup error: too many connections (2) (when run again for test 'second test')")

## A fresh-context interlude that fails only on its second run is reported
$connections_opened = 0
run = run_sections_fixture(<<~'RUBY', shared: false)
  ## first test
  1
  #=> 1

  $connections_opened += 1
  raise "too many connections (#{$connections_opened})" if $connections_opened > 1

  ## second test
  2
  #=> 2

  ## third test
  3
  #=> 3
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [false, [:passed, :passed], [:orphan]]
#==> run[:console].include?("too many connections (2) (when run again for test 'third test')")

## A fresh-context teardown that fails after every test is reported once
run = run_sections_fixture(<<~'RUBY', shared: false)
  ## first test
  1
  #=> 1

  ## second test
  2
  #=> 2

  raise 'cleanup failed'
RUBY
[run[:passed], run[:statuses], run[:infrastructure], run[:console].scan('Teardown failed').size]
#=> [true, [:passed, :passed], [:teardown], 1]


## What a failing setup printed is shown with its error
run = run_sections_fixture(<<~'RUBY')
  puts 'connecting to localhost:5432'
  raise 'connection refused'

  ## never runs
  1
  #=> 1
RUBY
run[:console]
#=~> /connecting to localhost:5432\n.*Global setup error: connection refused/m

## What a failing teardown printed is shown with its error
run = run_sections_fixture(<<~'RUBY')
  ## first test
  1
  #=> 1

  warn 'removing tmp/uploads'
  raise 'permission denied'
RUBY
run[:console]
#=~> /removing tmp\/uploads\n.*Teardown failed: permission denied/m

## What a setup printed is shown even when it raises a frozen exception
run = run_sections_fixture(<<~'RUBY')
  puts 'loading fixtures'
  raise RuntimeError.new('fixtures missing').freeze

  ## never runs
  1
  #=> 1
RUBY
run[:console]
#=~> /loading fixtures\n.*Global setup error: fixtures missing/m

## A fresh-context teardown's header, output and failure appear together after the last test
run = run_sections_fixture(<<~'RUBY', shared: false)
  @items = [1]

  ## adds an item
  @items << 2
  @items.size
  #=> 2

  ## starts again from one item
  @items.size
  #=> 1

  puts "teardown sees #{@items.size}"
  raise 'teardown boom' if @items.size == 2
RUBY
run[:console].lines.map { |line| line.gsub(/\e\[[\d;]*m/, '').strip }.grep(/\A(Test \d|Executing teardown|teardown sees|ERROR: Teardown failed)/).map { |line| line[/\A\S+ \S+/] }
#=> ['Test 1/2:', 'Test 2/2:', 'Executing teardown', 'teardown sees', 'ERROR: Teardown']

## A setup that raises an exception inheriting from Exception directly stops the file and is reported
run = run_sections_fixture(<<~'RUBY')
  class ConfigMissing < Exception; end

  puts 'reading config/app.yml'
  raise ConfigMissing, 'config/app.yml not found'

  ## never runs
  1
  #=> 1
RUBY
[run[:passed], run[:statuses], run[:infrastructure]]
#=> [false, [], [:setup]]
#==> run[:console].match?(/reading config\/app.yml\n.*Global setup error: config\/app.yml not found/m)

## A test that raises an exception inheriting from Exception directly is a test error, or passes #=!>
run = run_sections_fixture(<<~'RUBY')
  class ShutdownRequested < Exception; end

  ## stops the worker without saying so
  raise ShutdownRequested, 'worker stopping'
  #=> nil

  ## stops the worker on purpose
  raise ShutdownRequested, 'worker stopping'
  #=!> ShutdownRequested
RUBY
[run[:passed], run[:statuses]]
#=> [false, [:error, :passed]]

$connections_opened = nil
