# try/core/failure_summary_values_try.rb
#
# frozen_string_literal: true

# The failure summary at the end of a run describes each failing value as it
# was when its test ran. In fresh context the file's own constants are removed
# before the setup runs again for the next test, so a value whose inspect
# needs one of them can no longer be inspected by then.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def run_file(source, **options)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'gauges_try.rb')
    File.write(path, source)
    out  = StringIO.new
    code = Tryouts::CLI.new.run([path], stdout: out, stderr: out, **options)
    [code, out.string]
  end
end

gauges = <<~'RUBY'
  ## a pressure reading prints with its unit
  GAUGE_UNIT = 'psi'
  class Gauge
    def initialize(value) = @value = value
    def inspect = "#<Gauge #{@value}#{GAUGE_UNIT}>"
    def ==(other) = other.inspect == inspect
  end
  Gauge.new(3)
  #=> Gauge.new(4)

  ## a later test runs after the first one's constants are gone
  [1, 2].sum
  #=> 4
RUBY

## Both failures are listed with their values, and the run still counts them
code, output = run_file(gauges, shared_context: false)
[code, output.scan(/expected .*, got .*/)]
#=> [2, ["expected #<Gauge 4psi>, got #<Gauge 3psi>", "expected 4, got 3"]]

## A value whose inspect raises is described instead of stopping the summary
code, output = run_file(<<~'RUBY')
  ## a broken inspect
  class Meter
    def inspect = raise('no unit configured')
  end
  Meter.new
  #=> nil
RUBY
[code, output[/expected nil, got .*/]]
#=> [1, "expected nil, got #<Meter (inspect raised RuntimeError: no unit configured)>"]

opaque_then_more = <<~'RUBY'
  class Meter
    def inspect = raise('no unit configured')
  end

  ## a broken inspect
  Meter.new
  #=> nil

  ## a later reading that also fails
  [1, 2].sum
  #=> 4

  $meter_teardowns += 1
RUBY

## In every output mode a value whose inspect raises is shown without stopping the file: the next test and the teardown still run
[{}, { verbose: true }, { agent: true }, { quiet: true }].map do |options|
  $meter_teardowns = 0
  code, = run_file(opaque_then_more, **options)
  [code, $meter_teardowns]
end
#=> [[2, 1], [2, 1], [2, 1], [2, 1]]

## A value with no inspect method at all is described by its class
code, output = run_file("## a bare object\nBasicObject.new\n#=> nil\n")
[code, output[/got #<BasicObject \(inspect raised NoMethodError/]]
#=> [1, 'got #<BasicObject (inspect raised NoMethodError']

## The failure collector loads what it needs on its own
require 'open3'
require 'rbconfig'
collector = File.expand_path('../../lib/tryouts/failure_collector', __dir__)
Open3.capture2e(RbConfig.ruby, '-e', "require #{collector.inspect}; p Tryouts::FailureCollector.expectation_error('3', 'a_try.rb')").first
#=> "nil\n"
