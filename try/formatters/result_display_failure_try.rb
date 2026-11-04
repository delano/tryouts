# try/formatters/result_display_failure_try.rb
#
# frozen_string_literal: true

# A formatter that fails to show a test's result does not stop the file.
# The result is counted before it is shown, the error says which result it
# was, and the tests after it and the teardown still run.

require 'stringio'
require 'tempfile'
require_relative '../../lib/tryouts'

# Compact output with no way to show a failed test
class FailuresUnshown < Tryouts::CLI::CompactFormatter
  def test_result(result_packet)
    raise 'no room for failures' if result_packet.failed?

    super
  end
end

sums = <<~'RUBY'
  ## a wrong sum
  1 + 1
  #=> 3

  ## a right sum
  2 + 2
  #=> 4

  $sum_teardowns += 1
RUBY

file = Tempfile.new(['sums', '_try.rb'])
file.write(sums)
file.flush

console          = StringIO.new
output           = Tryouts::CLI::OutputManager.new(FailuresUnshown.new(stdout: console, stderr: console))
$sum_teardowns   = 0
batch            = Tryouts::TestBatch.new(Tryouts::StatementParser.new(file.path).parse, shared_context: true, output_manager: output)
batch_passed     = batch.run

## Every test runs and is counted, and the teardown runs
[batch_passed, batch.results.map(&:status), $sum_teardowns]
#=> [false, [:failed, :passed], 1]

## The error says which result could not be shown, and why
console.string.gsub(/\e\[[\d;]*m/, "")[/could not show.*/]
#=> 'could not show the result of "a wrong sum": RuntimeError: no room for failures'

file.close!
