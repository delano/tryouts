# try/translators/magic_comments_translation_try.rb
#
# frozen_string_literal: true

# A file's leading magic comments apply under --rspec and --minitest the way
# they do in direct mode, and generated code starts with them.

require 'tempfile'
require_relative '../test_helper'

source = <<~'RUBY'
  # frozen_string_literal: true

  ## string literals are frozen
  "abc".frozen?
  #=> true

  ## appending to a literal raises
  word = "abc"
  word << "d"
  #=!> error.is_a?(FrozenError)

  ## literals in an expectation are frozen too
  1
  #=> "one".frozen? ? 1 : 0
RUBY

file = Tempfile.new(['frozen_literals', '_try.rb'])
file.write(source)
file.flush
testrun = Tryouts::StatementParser.new(file.path).parse

## Every translated Minitest test passes with the file's magic comment
test_class = Tryouts::Translators::MinitestTranslator.new.translate(testrun)
test_class.public_instance_methods(false).grep(/\Atest_/).sort.map { |name| test_class.new(name).run.passed? }
#=> [true, true, true]

## Every translated RSpec example passes with the file's magic comment
group = Tryouts::Translators::RSpecTranslator.new.translate(testrun)
group.run
group.descendant_filtered_examples.map { |example| example.execution_result.status }
#=> [:passed, :passed, :passed]

## Generated RSpec code starts with the magic comment
Tryouts::Translators::RSpecTranslator.new.generate_code(testrun).lines.first
#=> "# frozen_string_literal: true\n"

## Generated Minitest code starts with the magic comment
Tryouts::Translators::MinitestTranslator.new.generate_code(testrun).lines.first
#=> "# frozen_string_literal: true\n"

## Generated Minitest code asserts on the expectation's own source
Tryouts::Translators::MinitestTranslator.new.generate_code(testrun)
#=~> /^    assert_equal "one"\.frozen\? \? 1 : 0, result$/
#=~> /^    assert error\.is_a\?\(FrozenError\), "Exception expectation failed: error\.is_a\?\(FrozenError\)"$/

file.close!
