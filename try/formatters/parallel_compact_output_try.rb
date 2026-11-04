# try/formatters/parallel_compact_output_try.rb
#
# frozen_string_literal: true

# Under --parallel several files run at the same time. The compact output
# still shows each file as one piece: its header, its tests and its result
# line, with no other file's lines in between.

require 'open3'
require 'rbconfig'
require 'tmpdir'

# Runs `try` with the flags on each named source, saved as its own file, and
# returns what it wrote to stdout above the failure summary, split into one
# block per file header, without colours or timings
def compact_blocks(sources, *flags)
  try_command = File.expand_path('../../exe/try', __dir__)
  Dir.mktmpdir do |dir|
    paths = sources.map do |name, source|
      path = File.join(dir, "#{name}_try.rb")
      File.write(path, source)
      path
    end
    output, _errors, _status = Open3.capture3(RbConfig.ruby, try_command, *flags, *paths)
    text = output.force_encoding(Encoding::UTF_8).split(/^-+$/).first
    text = text.gsub(/\e\[[\d;]*m/, '').gsub(/ \([\d.]+(μs|ms|s)\)$/, '')
    text.split(/^(?=\S+_try\.rb: \d+ tests$)/).map { |block| block.lines.map(&:strip).reject(&:empty?) }.reject(&:empty?)
  end
end

# The slow file starts first and finishes last
slow  = "## slow test\nsleep 0.2\n1\n#=> 1\n"
quick = "## quick test\n2\n#=> 2\n\n## quick failure\n2\n#=> 3\n"

## Each file's tests and result line follow its own header
compact_blocks({ a_slow: slow, b_quick: quick }, '-j', '2').sort
#=> [['a_slow_try.rb: 1 tests', '✓ slow test', '✓ 1 passed'], ['b_quick_try.rb: 2 tests', '✓ quick test', '✗ quick failure', 'got: 2', '2', '✗ 1/2 passed, 1 failed']]

## With -f only failures are listed, still under their own file
compact_blocks({ a_slow: slow, b_quick: quick }, '-f', '-j', '2').sort
#=> [['a_slow_try.rb: 1 tests', '✓ 1 passed'], ['b_quick_try.rb: 2 tests', '✗ quick failure', 'got: 2', '2', '✗ 1/2 passed, 1 failed']]
