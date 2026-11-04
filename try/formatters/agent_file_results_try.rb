# try/formatters/agent_file_results_try.rb
#
# frozen_string_literal: true

# --agent output is read by tools, so its counts must match what ran: the
# SUMMARY counts come from the whole run, every failure is listed under the
# file it happened in (also under --parallel), and setup, interlude and
# teardown failures show up in the summary and with their file.

require 'open3'
require 'rbconfig'
require 'tmpdir'

# Runs `try --agent` on each named source, saved as its own file, and
# returns what it printed
def agent_report(sources, *flags)
  try_command = File.expand_path('../../exe/try', __dir__)
  Dir.mktmpdir do |dir|
    paths = sources.map do |name, source|
      path = File.join(dir, "#{name}_try.rb")
      File.write(path, source)
      path
    end
    output, _status = Open3.capture2e(RbConfig.ruby, try_command, '--agent', *flags, *paths)
    output
  end
end

# The failing test descriptions listed under each file heading
def tests_by_file(report)
  report.split("\nCONTEXT:").first.scan(/^(\S+_try\.rb):\n((?:  .*\n?)*)/).to_h do |file, body|
    [file, body.scan(/Test: (.+)/).flatten]
  end
end

interlude_stops = <<~'RUBY'
  ## first test fails
  1
  #=> 2

  raise 'interlude broke'

  ## never runs
  3
  #=> 3
RUBY

setup_stops = <<~'RUBY'
  raise 'setup broke'

  ## never runs
  1
  #=> 1
RUBY

# Each test waits a moment, so files running in parallel overlap
two_failures = ->(name) { "## #{name} one\nsleep 0.01\n1\n#=> 2\n\n## #{name} two\nsleep 0.01\n2\n#=> 3\n" }

## A failing test in a file an interlude stopped is reported as failing
report = agent_report(interlude: interlude_stops)
report[/^\d+ testcases passed.* files/]
#=> '0 testcases passed, 1 failed, 1 not run in 1 files'

## The stopped file is listed with its failure, what stopped it and what did not run
report = agent_report(interlude: interlude_stops)
tests_by_file(report)
#=> { 'interlude_try.rb' => ['first test fails'] }
#==> report.include?("interlude_try.rb:\n  interlude failed, 1 not run\n  L3: expected 2, got 1")

## The summary says a file failed even when every test that ran passed
report = agent_report(setup: setup_stops, fine: "## fine\n1\n#=> 1\n")
report[/^Failed files: .*$/]
#=> 'Failed files: 1 of 2 (1 setup failure)'

## Critical focus does not claim there were no critical errors when setup failed
report = agent_report({ setup: setup_stops }, '--agent-focus', 'critical')
[report.include?('No critical errors found'), report[/^\d+ files? with critical errors/]]
#=> [false, '1 file with critical errors']

## files_under_test counts every file given, also one that does not parse
report = agent_report(setup: setup_stops, unparsable: "## broken\ndef (\n#=> 1\n", fine: "## fine\n1\n#=> 1\n")
report[/files_under_test: \d+/]
#=> 'files_under_test: 3'
#==> report.include?("Failed files: 2 of 3 (1 setup failure, 1 file failure)\n")

## Under --parallel each failure is listed under its own file, and the summary counts them all
names  = %w[alpha beta gamma delta]
report = agent_report(names.to_h { |name| [name, two_failures.call(name)] }, '-j', '4')
tests_by_file(report).sort.to_h
#=> names.sort.to_h { |name| ["#{name}_try.rb", ["#{name} one", "#{name} two"]] }
#==> report.include?('0 testcases passed, 8 failed in 4 files')
