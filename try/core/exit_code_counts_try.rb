# try/core/exit_code_counts_try.rb
#
# frozen_string_literal: true

# The exit code is the number of failing tests plus the setup, interlude and
# teardown failures, each counted once for the file it happened in.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def run_files(sources, **options)
  Dir.mktmpdir do |dir|
    paths = sources.each_with_index.map do |source, idx|
      path = File.join(dir, "file#{idx + 1}_try.rb")
      File.write(path, source)
      path
    end
    out  = StringIO.new
    code = Tryouts::CLI.new.run(paths, stdout: out, stderr: out, **options)
    [code, out.string]
  end
end

broken_setup = <<~'RUBY'
  raise 'setup broke'

  ## never runs
  1
  #=> 1
RUBY

broken_interlude = <<~'RUBY'
  ## first test fails
  1
  #=> 2

  raise 'interlude broke'

  ## never runs
  3
  #=> 3
RUBY

broken_teardown = <<~'RUBY'
  ## passing test
  1
  #=> 1

  puts 'teardown says hi'
  raise 'teardown broke'
RUBY

## Three files whose setup fails count one failure each
run_files([broken_setup, broken_setup, broken_setup]).first
#=> 3

## A file whose setup failed is not reported as passing
_, output = run_files([broken_setup])
[output.include?('✓'), output.include?('setup failed')]
#=> [false, true]

## An interlude that aborts the file counts on top of the failed test
run_files([broken_interlude]).first
#=> 2

## A teardown failure makes the exit code non-zero even when every test passed
run_files([broken_teardown]).first
#=> 1

## The same teardown failure counts once in fresh context, where teardown runs after each test
teardown_after_each = <<~'RUBY'
  ## first passing test
  1
  #=> 1

  ## second passing test
  2
  #=> 2

  raise 'teardown broke'
RUBY
run_files([teardown_after_each], shared_context: false).first
#=> 1

## A file whose teardown failed is not counted as a passing file
_, output = run_files([broken_teardown, "## fine\n1\n#=> 1\n"])
output[/\d+ of \d+ files passed/]
#=> "1 of 2 files passed"

## Passing files still exit 0
run_files(["## fine\n1\n#=> 1\n", "## also fine\n2\n#=> 2\n"]).first
#=> 0

## A file that cannot be read is reported by name and counts as a failed file
Dir.mktmpdir do |dir|
  unreadable = File.join(dir, 'folder_try.rb')
  Dir.mkdir(unreadable)
  passing = File.join(dir, 'fine_try.rb')
  File.write(passing, "## fine\n1\n#=> 1\n")
  out  = StringIO.new
  code = Tryouts::CLI.new.run([unreadable, passing], stdout: out, stderr: out)
  [code, out.string.include?('folder_try.rb: Is a directory'), out.string[/\d+ of \d+ files passed/]]
end
#=> [1, true, '1 of 2 files passed']
