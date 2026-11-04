# try/formatters/top_level_include_try.rb
#
# frozen_string_literal: true

# A file's top-level `include` mixes its module into Object, so its methods
# are visible on every object for the rest of the run, the framework's own
# included. What a test file names its methods must not change the report.

require 'open3'
require 'rbconfig'
require 'tmpdir'

# Runs `try` with the flags on each named source, saved as its own file, and
# returns what it printed, without colours
def try_output(sources, *flags)
  try_command = File.expand_path('../../exe/try', __dir__)
  Dir.mktmpdir do |dir|
    paths = sources.map do |name, source|
      path = File.join(dir, "#{name}_try.rb")
      File.write(path, source)
      path
    end
    output, _status = Open3.capture2e(RbConfig.ruby, try_command, *flags, *paths)
    output.force_encoding(Encoding::UTF_8).gsub(/\e\[[\d;]*m/, '')
  end
end

prices = <<~'RUBY'
  module Money
    def format(cents)
      cents.negative? ? "-$%.2f" % (-cents / 100.0) : "$%.2f" % (cents / 100.0)
    end
  end
  include Money

  ## A price is shown in dollars
  format(199)
  #=> "$1.99"

  ## A refund is shown with a leading minus
  format(-50)
  #=> "-$0.5"
RUBY

measures = <<~'RUBY'
  module Units
    def system
      :metric
    end
  end
  include Units

  ## Distances use the metric system
  system
  #=> :metric
RUBY

alerts = <<~'RUBY'
  module Alerts
    def warn(message)
      (@alerts ||= []) << message
    end
  end
  include Alerts

  ## A warning is kept with the others
  warn('disk almost full')
  #=> ['disk almost full']

  raise "#{@alerts.size} alert not sent" unless @alerts.empty?
RUBY

sums = "## Sums add up\n2 + 2\n#=> 5\n"

## Verbose output shows the failing test of a file whose module defines format
output = try_output({ prices: prices }, '-v')
[output.include?('Expected: "-$0.5"'), output.include?('Actual:   "-$0.50"'), output.include?('wrong number of arguments')]
#=> [true, true, false]

## The module stays mixed in, and the next file and the run's totals are reported too
output = try_output({ prices: prices, sums: sums }, '-v')
[output.include?('Expected: 5'), output[/^Files: .*$/]]
#=> [true, 'Files:     0 of 2 passed']

## Agent output keeps its version control line when a file's module defines system
plain   = try_output({ sums: sums }, '--agent')[/^  vcs: .*$/]
shadows = try_output({ measures: measures, sums: sums }, '--agent')[/^  vcs: .*$/]
shadows
#=> plain

## Debug output still reaches stderr when a file's module defines warn
try_output({ alerts: alerts }, '-D')
#=~> /DEBUG Teardown failed with .*1 alert not sent/
