# try/core/detached_expectations_try.rb
#
# frozen_string_literal: true

# An expectation needs a statement above it in its own test. One written
# before the first statement, or directly under a `##` line, has nothing to
# assert on. It is a warning and a test of its own that always fails, so a
# file whose only expectation is detached does not pass quietly.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def run_file(source, **options)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'detached_try.rb')
    File.write(path, source)
    out  = StringIO.new
    code = Tryouts::CLI.new.run([path], stdout: out, stderr: out, **options)
    [code, out.string.gsub(/\e\[[\d;]*m/, '')]
  end
end

def batch_for(source, shared: true)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'detached_try.rb')
    File.write(path, source)
    testrun = Tryouts::StatementParser.new(path, strict: true).parse
    batch   = Tryouts::TestBatch.new(testrun, shared_context: shared)
    batch.run
    batch
  end
end

only_detached = <<~'RUBY'
  ## first
  total = 1
  ## second
  #=> 1
RUBY

under_a_description = <<~'RUBY'
  ## counts items
  [1, 2, 3].size
  #=> 3

  ## empty list has no items
  #=> 0
  #=:> Integer

  ## next
  [].size
  #=> 0
RUBY

leading = <<~'RUBY'
  #=> 1
  total = 1

  ## first
  total
  #=> 1
RUBY

## A file whose only expectation is detached fails instead of passing with no tests
code, output = run_file(only_detached)
[code, output[/Expectation at line 4 has no statement.*$/]]
#=> [1, "Expectation at line 4 has no statement between it and the description at line 3"]

## The same file fails in fresh context
run_file(only_detached, shared_context: false).first
#=> 1

## Expectations under one description make one failing test with that name
batch = batch_for(under_a_description)
batch.results.map { |r| [r.test_case.description, r.status] }
#=> [["counts items", :passed], ["empty list has no items", :failed], ["next", :passed]]

## The detached test fails at its first expectation's line
batch = batch_for(under_a_description, shared: false)
failed = batch.results.find(&:failed?)
[failed.failure_line + 1, failed.test_case.line_range.first + 1, failed.test_case.line_range.last + 1]
#=> [6, 5, 7]

## Its failure says there is no statement above it to assert on
batch = batch_for(under_a_description)
batch.results.find(&:failed?).expected_results.first
#=> "a statement above line 6 to assert on (there is none in this test), got: #=> 0"

## A detached expectation before the first statement is an unnamed failing test, even in strict mode
batch = batch_for(leading)
batch.results.map { |r| [r.test_case.description, r.status, r.failure_line + 1] }
#=> [["", :failed, 1], ["first", :passed, 6]]

## The failure summary points at line 1 for a detached expectation on the first line
code, output = run_file(leading)
[code, output[/detached_try\.rb:\d+$/]]
#=> [1, "detached_try.rb:1"]

## A mistyped operator straight under a description is detached, so it fails too
code, output = run_file(<<~'RUBY')
  ## first
  1
  #=> 1

  ## second
  #=X> 2
RUBY
code
#=> 1
