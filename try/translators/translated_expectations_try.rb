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

  ## wrong error class, with a comment
  Integer('twelve')
  #=!> TypeError # the wrong class

  ## error class, with a comment
  Integer('twelve')
  #=!> ArgumentError # invalid input

  ## not nil, but raised
  Integer('twelve')
  #=!> ArgumentError
  #=*>

  ## the expectation variables
  42
  #==> _ == 42
  #==> error.nil?
  #==> elapsed_ms < 1000

  ## break gives nil
  1
  #=> break

  ## next gives the value
  1
  #=> next 1

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
  false, true, false, true, false, true,
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

## An RSpec example sees a constant the setup defined, which stays for the rest of the run
setup_constant = parse.call('setup_constant', "TranslatedPriceLimit = 3\n\n## the limit\nTranslatedPriceLimit\n#=> 3\n")
[rspec_statuses.call(setup_constant), defined?(TranslatedPriceLimit)]
#=> [[:passed], 'constant']

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

## A check that passes never calls inspect on the values, so an object whose inspect raises passes as in direct mode
opaque = <<~'RUBY'
  class TranslatedOpaque
    def ==(other) = other.is_a?(TranslatedOpaque)
    def inspect = raise('inspected')
  end

  ## two of a kind
  TranslatedOpaque.new
  #=> TranslatedOpaque.new
RUBY
opaque_run = parse.call('opaque', opaque)
[minitest_passed.call(opaque_run), rspec_statuses.call(opaque_run)]
#=> [[true], [:passed]]

## Captured output with invalid UTF-8 is read with the bytes replaced, as in direct mode
binary = parse.call('binary_output', "## a byte, then text\n$stdout.write(\"\\xFF\".b)\nputs 'done'\n#=1> /done/\n")
[minitest_passed.call(binary), rspec_statuses.call(binary)]
#=> [[true], [:passed]]

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
#=~> /\A33 runs, \d+ assertions, 20 failures, 0 errors\z/

## Generated Minitest code says why an untranslated expectation fails
generate.call('--generate-minitest', operators_run.source_file)
#=~> /flunk\("line 123: #=%> 1 is not translated to Minitest; run the tryouts file with --minitest to check it"\)/
#=~> /flunk\("line 134: expected a statement above line 134 to assert on \(there is none in this test\), got: #=> 1"\)/

## Generated RSpec code loads and fails the tests direct mode fails, and the passing ones whose operator it does not translate
File.write(File.join(dir, 'operators_spec.rb'), generate.call('--generate-rspec', operators_run.source_file))
output, = Open3.capture2e(RbConfig.ruby, Gem.bin_path('rspec-core', 'rspec'), File.join(dir, 'operators_spec.rb'))
output[/^\d+ examples, \d+ failures.*$/]
#=> "33 examples, 20 failures"

# Tests whose code or expectations use, for something of their own, a name
# the generated code needs: two fail in direct mode, the others pass
own_names = <<~'RUBY'
  ## a test that only returns an error has not raised it
  error = ArgumentError.new('only returned')
  error
  #=!> ArgumentError

  ## a word kept in a local named error is not an error
  error = 'just a word'
  Integer('12')
  #=:> Integer
  #=*>

  ## a local named started leaves the run time alone
  started = Time.now
  :ok
  #==> elapsed_ms < 1000

  ## an expectation that assigns result leaves the test's value alone
  4
  #=> result = 5

  ## a local named expected keeps its value
  expected = 'bad input'
  raise ArgumentError, expected
  #=!> ArgumentError
  #==> error.message == expected

  ## a local named result is not the test's value
  result = [1, 2, 3]
  result.size
  #=> 3
  #==> result == 3
RUBY
own_names_run = parse.call('own_names', own_names)

## Direct mode passes and fails the tests that use the generated code's names in this pattern
batch = Tryouts::TestBatch.new(own_names_run, shared_context: false)
batch.run
batch.results.map(&:passed?)
#=> [false, true, true, false, true, true]

## Generated Minitest code fails the same two of them, and none errors
File.write(File.join(dir, 'own_names_test.rb'), generate.call('--generate-minitest', own_names_run.source_file))
output, = Open3.capture2e(RbConfig.ruby, File.join(dir, 'own_names_test.rb'))
[output[/^\d+ runs, \d+ assertions, \d+ failures, \d+ errors/], output.scan(/^Test\w+#test_(\d+)_/).flatten.sort]
#=~> /\A\["6 runs, \d+ assertions, 2 failures, 0 errors", \["000", "003"\]\]\z/

## Generated RSpec code fails the same two of them
File.write(File.join(dir, 'own_names_spec.rb'), generate.call('--generate-rspec', own_names_run.source_file))
output, = Open3.capture2e(RbConfig.ruby, Gem.bin_path('rspec-core', 'rspec'), File.join(dir, 'own_names_spec.rb'))
[output[/^\d+ examples, \d+ failures$/], output.scan(/^rspec \S+ # own_names_try (.+)$/).flatten.sort]
#=> ["6 examples, 2 failures", ["a test that only returns an error has not raised it", "an expectation that assigns result leaves the test's value alone"]]

## The generated code adds an underscore to a name the test uses, and an expectation reads its own result
generate.call('--generate-minitest', own_names_run.source_file)
#=~> /^    rescue Exception => error_\n      raise if error_\.is_a\?\(SignalException\) \|\| error_\.is_a\?\(SystemExit\)\n      error_\n    end\n    refute_nil error_$/
#=~> /^    assert_same\(true, ->\(result\) \{ \(\n      result == 3\n    \) \}\.call\(result_\)\)$/

FileUtils.remove_entry(dir)
