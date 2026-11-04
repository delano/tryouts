# try/translators/translated_expectations_try.rb
#
# frozen_string_literal: true

# --rspec and --minitest judge every expectation the way direct mode does:
# the test code runs once, and each expectation goes through the same
# evaluator. A malformed or detached expectation fails there as it does in
# direct mode. Code written by --generate-rspec and --generate-minitest
# fails a test direct mode fails, and an expectation it has no assertion for
# fails rather than vanishing.

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require_relative '../test_helper'

dir         = Dir.mktmpdir
try_command = File.expand_path('../../exe/try', __dir__)

# Saves source as a tryouts file and returns its path
write_file = lambda do |name, source|
  path = File.join(dir, "#{name}_try.rb")
  File.write(path, source)
  path
end

parse = ->(name, source) { Tryouts::StatementParser.new(write_file.call(name, source)).parse }

minitest_passed = lambda do |testrun|
  test_class = Tryouts::Translators::MinitestTranslator.new.translate(testrun)
  test_class.public_instance_methods(false).grep(/\Atest_/).sort.map { |name| test_class.new(name).run.passed? }
end

# What try --generate-minitest or --generate-rspec writes for a file (its
# parser warnings go to stderr)
generate = ->(flag, path) { Open3.capture3(RbConfig.ruby, try_command, flag, path).first }

rspec_statuses = lambda do |testrun|
  group = Tryouts::Translators::RSpecTranslator.new.translate(testrun)
  group.run
  group.descendant_filtered_examples.map { |example| example.execution_result.status }
end

# One passing and one failing test for each operator, alternating, then a
# malformed and a detached expectation
operators = <<~'RUBY'
  ## equal, with a trailing comment
  [1, 2].size
  #=> 2    # two items

  ## not equal
  [1, 2].size
  #=> 3

  ## a hash literal
  { a: 1 }
  #=> { a: 1 }

  ## not true
  -1
  #==> result.positive?

  ## true
  1
  #==> result.positive?

  ## not false
  1
  #=/=> result.positive?

  ## false
  -1
  #=/=> result.positive?

  ## not a boolean
  [1]
  #=|> result.size

  ## a boolean
  []
  #=|> result.empty?

  ## wrong error class
  Integer('twelve')
  #=!> TypeError

  ## error class
  Integer('twelve')
  #=!> ArgumentError
  #=~> /invalid value/

  ## nothing raised
  Integer('12')
  #=!> ArgumentError

  ## error expression
  Integer('twelve')
  #=!> error.message.include?('twelve')

  ## wrong type
  'abc'
  #=:> Integer

  ## type
  'abc'
  #=:> String

  ## no match
  'abc'
  #=~> /z/

  ## match
  'abc'
  #=~> /b/

  ## nil
  nil
  #=*>

  ## not nil
  :apple
  #=*>

  ## equal after all
  2
  #=<> 2

  ## not equal after all
  2
  #=<> 3

  ## other output
  puts 'hello'
  #=1> 'goodbye'

  ## output
  puts 'hello'
  #=1> 'hello'

  ## too slow
  sleep 0.05
  #=%> 1

  ## fast enough
  1 + 1
  #=%> 1000

  ## a mistyped operator
  1
  #=X> 1

  ## no code above it
  #=> 1
RUBY

expected_passes = [
  true, false, true, false, true, false, true, false, true, false, true, false, true,
  false, true, false, true, false, true, false, true, false, true, false, true, false, false
]

operators_run = parse.call('operators', operators)
only_detached = parse.call('only_detached', "@total = 3\n\n## total is three\n#=> 3\n")

## Direct mode passes and fails the operator tests in this pattern
batch = Tryouts::TestBatch.new(operators_run, shared_context: false)
batch.run
batch.results.map(&:passed?)
#=> expected_passes

## Under --minitest each operator test passes or fails as in direct mode
minitest_passed.call(operators_run)
#=> expected_passes

## Under --rspec each operator test passes or fails as in direct mode
rspec_statuses.call(operators_run).map { |status| status == :passed }
#=> expected_passes

## A failing Minitest test says what the evaluator expected and got
test_class = Tryouts::Translators::MinitestTranslator.new.translate(parse.call('one_failure', "## sizes\n[1, 2].size\n#=> 3\n"))
test_class.new(test_class.public_instance_methods(false).grep(/\Atest_/).first).run.failures.first.message
#=> "#{dir}/one_failure_try.rb:3: expected 3, got 2"

## A file whose only expectation is detached has one failing Minitest test
minitest_passed.call(only_detached)
#=> [false]

## A file whose only expectation is detached has one failing RSpec example
rspec_statuses.call(only_detached)
#=> [:failed]

## An RSpec example sees a constant the setup defined, which goes when the examples are done
setup_constant = parse.call('setup_constant', "TranslatedPriceLimit = 3\n\n## the limit\nTranslatedPriceLimit\n#=> 3\n")
[rspec_statuses.call(setup_constant), defined?(TranslatedPriceLimit)]
#=> [[:passed], nil]

## An RSpec example sees a class an interlude above it defined
interlude_class = <<~'RUBY'
  ## a plain number
  1
  #=> 1

  class TranslatedShape
    def sides = 3
  end

  ## the interlude's class
  TranslatedShape.new.sides
  #=> 3
RUBY
rspec_statuses.call(parse.call('interlude_class', interlude_class))
#=> [:passed, :passed]

## next and break in an expectation leave the expression, as in direct mode
jumps = parse.call('jumps', "## next\n1\n#=> next 1\n\n## break\n2\n#=> break 2\n")
[minitest_passed.call(jumps), rspec_statuses.call(jumps)]
#=> [[true, true], [:passed, :passed]]

## try --rspec exits non-zero when an example fails, and the next file runs only its own examples
failing = write_file.call('rspec_fails', "## wrong sum\n1 + 1\n#=> 3\n")
passing = write_file.call('rspec_passes', "## right sum\n1 + 1\n#=> 2\n")
output, status = Open3.capture2e(RbConfig.ruby, try_command, '--rspec', failing, passing)
[status.success?, output.scan(/^\d+ examples?, \d+ failures?$/)]
#=> [false, ["1 example, 1 failure", "1 example, 0 failures"]]

## try --minitest exits non-zero for a file whose only expectation is detached
output, status = Open3.capture2e(RbConfig.ruby, try_command, '--minitest', write_file.call('detached', "## total\n#=> 3\n"))
[status.success?, output[/^\d+ runs, \d+ assertions, \d+ failures/]]
#=> [false, "1 runs, 1 assertions, 1 failures"]

## Generated Minitest code loads and fails the tests direct mode fails, and the passing ones whose operator it does not translate
File.write(File.join(dir, 'operators_test.rb'), generate.call('--generate-minitest', operators_run.source_file))
output, = Open3.capture2e(RbConfig.ruby, File.join(dir, 'operators_test.rb'))
output[/^\d+ runs, \d+ assertions, \d+ failures, \d+ errors/]
#=~> /\A27 runs, \d+ assertions, 17 failures, 0 errors\z/

## Generated Minitest code says why an untranslated expectation fails
generate.call('--generate-minitest', operators_run.source_file)
#=~> /flunk\("line 96: #=%> 1 is not translated to Minitest; run the tryouts file with --minitest to check it"\)/
#=~> /flunk\("line 107: expected a statement above line 107 to assert on \(there is none in this test\), got: #=> 1"\)/

## Generated RSpec code loads and fails the tests direct mode fails, and the passing ones whose operator it does not translate
File.write(File.join(dir, 'operators_spec.rb'), generate.call('--generate-rspec', operators_run.source_file))
output, = Open3.capture2e(RbConfig.ruby, Gem.bin_path('rspec-core', 'rspec'), File.join(dir, 'operators_spec.rb'))
output[/^\d+ examples, \d+ failures.*$/]
#=> "27 examples, 17 failures"

FileUtils.remove_entry(dir)
