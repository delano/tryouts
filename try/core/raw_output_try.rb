# try/core/raw_output_try.rb
#
# frozen_string_literal: true

# Output that is not valid UTF-8, and test files that define methods Ruby's
# own Kernel also has, leave the report and the exit status intact.

require 'open3'
require 'rbconfig'
require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

TRY_EXECUTABLE = File.expand_path('../../exe/try', __dir__)

def run_file(source, *flags)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'report_try.rb')
    File.write(path, source)
    output, status = Open3.capture2e(RbConfig.ruby, TRY_EXECUTABLE, *flags, path)
    [status.exitstatus, output.scrub]
  end
end

## A test that prints raw bytes and then text can still check its output
code, output = run_file(<<~'RUBY')
  ## a header followed by a status line
  print "\xFF\xFE".b
  puts 'done ✓'
  #=1> "done ✓"
  #=1> /done/
RUBY
[code, output[/\d+ passed/]]
#=> [0, "1 passed"]

## A setup error whose message has invalid bytes is still listed by --agent
code, output = run_file(<<~'RUBY', '--agent')
  raise "unreadable header \xFF"

  ## never runs
  1
  #=> 1
RUBY
[code, output.include?('Global setup error'), output.include?('not run')]
#=> [1, true, true]

## A file that includes its own exit and warn still fails the run when a test fails
code, output = run_file(<<~'RUBY')
  module Parking
    def exit(ticket) = "#{ticket} paid"
    def warn(note) = "#{note} noted"
  end
  include Parking

  ## the second ticket is not paid
  exit('A12')
  #=> 'B7 paid'
RUBY
[code, output[/1 failed/]]
#=> [1, "1 failed"]
