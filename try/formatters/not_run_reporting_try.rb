# try/formatters/not_run_reporting_try.rb
#
# frozen_string_literal: true

# A setup or interlude failure stops the file. The tests below it never run,
# and every output mode says how many: in the file's own summary line and in
# the grand total.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

# Runs each source as its own *_try.rb file and returns the console output
def console_for(sources, **options)
  Dir.mktmpdir do |dir|
    paths = sources.each_with_index.map do |source, idx|
      path = File.join(dir, "stops#{idx + 1}_try.rb")
      File.write(path, source)
      path
    end
    out = StringIO.new
    Tryouts::CLI.new.run(paths, stdout: out, stderr: out, **options)
    out.string.gsub(/\e\[[\d;]*m/, '')
  end
end

interlude_stops = <<~'RUBY'
  ## the first test passes
  1
  #=> 1

  raise 'interlude broke'

  ## never runs
  2
  #=> 2

  ## never runs either
  3
  #=> 3
RUBY

setup_stops = <<~'RUBY'
  raise 'setup broke'

  ## never runs
  1
  #=> 1
RUBY

## The verbose file summary counts the tests that never ran
console_for([interlude_stops], verbose: true)[/Out of .*failed/]
#=> "Out of 3 tests: 1 passed, 2 not run, interlude failed"

## The compact file summary counts them too
console_for([interlude_stops])[/✗ .*failed/]
#=> "✗ 1/3 passed, 2 not run, interlude failed"

## The grand total adds up the tests that never ran in every file
total = console_for([interlude_stops, setup_stops]).lines.grep(/not run/).last
total[/[^(]*/].strip
#=> "1 tests passed, 3 not run"

## Quiet mode marks each test that never ran with an S
console_for([interlude_stops], quiet: true).scan(/^[.FES]+$/).join
#=> ".SS"

## Quiet mode's total counts them
console_for([interlude_stops, setup_stops], quiet: true)[/Total: [^(]*/]
#=> "Total: 1 passed, 3 not run "

## In fresh context the count is the same
console_for([interlude_stops], shared_context: false)[/✗ .*failed/]
#=> "✗ 1/3 passed, 2 not run, interlude failed"

## A file whose tests all ran says nothing about tests not run
console_for(["## fine\n1\n#=> 1\n", "## also fine\n2\n#=> 2\n"]).include?('not run')
#=> false

## The live status display counts the tests a file did not run
state = Tryouts::CLI::TestRunState.empty
state = state.update_from_event(:file_end, 'stops1_try.rb', { framework: :direct, context: :shared, not_run: 2 })
state = state.update_from_event(:file_end, 'stops2_try.rb', { framework: :direct, context: :shared, not_run: 1 })
[state.not_run, state.files_completed]
#=> [3, 2]
