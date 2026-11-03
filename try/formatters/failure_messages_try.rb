# try/formatters/failure_messages_try.rb
#
# frozen_string_literal: true

# A failure is reported at the line of the expectation that failed, and the
# expected/actual pair printed beside it belongs to that same expectation,
# not to the first one in the test.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def run_try(source, **options)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'pair_try.rb')
    File.write(path, source)
    out  = StringIO.new
    code = Tryouts::CLI.new.run([path], stdout: out, stderr: out, **options)
    [code, out.string]
  end
end

fixture = <<~'RUBY'
  ## sorted pair
  [1, 2].sort
  #=> [1, 2]
  #=> [2, 1]
  #==> result.size == 2
RUBY

## The failure summary describes the failing expectation, not the first one
code, output = run_try(fixture)
summary = output[/Failed Tests:.*/m]
[code, summary.include?('pair_try.rb:4'), summary.include?('expected [2, 1], got [1, 2]')]
#=> [1, true, true]

## The summary never claims a value failed against itself
_, output = run_try(fixture)
output.include?('expected [1, 2], got [1, 2]')
#=> false

## Agent output pairs the failing line with its own expected and actual
_, output = run_try(fixture, agent: true)
output[/^\s*L4: .*$/].strip
#=> "L4: expected [2, 1], got [1, 2]"

## Verbose failure listing uses the failing expectation too
_, output = run_try(fixture, verbose: true, fails_only: true)
output[/=== FAILURES ===.*/m].include?('expected [2, 1], got [1, 2]')
#=> true

## Compact output shows the actual value of the failing expectation
boolean_fixture = <<~'RUBY'
  ## list size
  [1, 2, 3]
  #=> [1, 2, 3]
  #==> result.size == 4
RUBY
_, output = run_try(boolean_fixture)
output[/got: .*$/]
#=> "got: false"
