# try/translators/rspec_translator_try.rb
#
# frozen_string_literal: true

# Tests for RSpecTranslator functionality

require_relative '../test_helper'
require_relative '../../lib/tryouts/translators/rspec_translator'
require_relative '../../lib/tryouts/test_case'

translator = Tryouts::Translators::RSpecTranslator.new

setup_code = Tryouts::Setup.new(
  code: "puts 'before all setup'",
  line_range: 1..1,
  path: 'test.rb'
)

test_case = Tryouts::TestCase.new(
  description: "simple multiplication",
  code: "2 * 3",
  expectations: [Tryouts::Expectation.new(content: "6", type: :regular)],
  line_range: 2..3,
  path: 'test.rb',
  source_lines: ["2 * 3", "#=> 6"],
  first_expectation_line: 3
)

testrun = Tryouts::Testrun.new(
  setup: setup_code,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'math_test.rb',
  metadata: {},
  warnings: []
)

generated_code = translator.generate_code(testrun)

exception_test_case = Tryouts::TestCase.new(
  description: "argument error test",
  code: "raise ArgumentError, 'test error'",
  expectations: [Tryouts::Expectation.new(content: "error.is_a?(ArgumentError)", type: :exception)],
  line_range: 4..5,
  path: 'test.rb',
  source_lines: ["raise ArgumentError, 'test error'", "#=!> error.is_a?(ArgumentError)"],
  first_expectation_line: 5
)

exception_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [exception_test_case],
  teardown: nil,
  source_file: 'error_test.rb',
  metadata: {},
  warnings: []
)

exception_code = translator.generate_code(exception_testrun)

@test_case_1 = Tryouts::TestCase.new(
  description: "string concatenation",
  code: "'hello' + ' world'",
  expectations: [Tryouts::Expectation.new(content: "'hello world'", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["'hello' + ' world'", "#=> 'hello world'"],
  first_expectation_line: 2
)

## TEST: Translator initializes successfully when rspec is available
translator.class.name
#=> "Tryouts::Translators::RSpecTranslator"

## TEST: Generate code creates valid RSpec describe structure
generated_code.include?("RSpec.describe 'math_test' do")
#=> true

## TEST: Generated code contains before(:all) block when setup present
generated_code.include?("before(:all)")
#=> true

## TEST: Generated code contains setup content
generated_code.include?("puts 'before all setup'")
#=> true

## TEST: Generated code contains it block with description
generated_code.include?('it "simple multiplication" do')
#=> true

## TEST: Generated code runs the test code once into result
generated_code
#=~> /^    result = begin\n      2 \* 3\n    end$/

## TEST: Generated code compares result with the expectation on its own line in parentheses
generated_code
#=~> /^    expect\(result\)\.to eq\(\(\n      6\n    \)\)$/

## TEST: Exception expectation rescues any error but a signal or exit into error
exception_code
#=~> /^      raise ArgumentError, 'test error'\n    rescue Exception => error\n      raise if error\.is_a\?\(SignalException\) \|\| error\.is_a\?\(SystemExit\)\n      error$/

## TEST: Exception expectation requires an error and a truthy expression
exception_code
#=~> /^    expected = \(\n      error\.is_a\?\(ArgumentError\)\n    \)\n    expect\(error\)\.not_to be_nil\n    if expected\.is_a\?\(Module\)\n      expect\(error\)\.to be_a\(expected\)\n    else\n      expect\(expected\)\.to be_truthy\n    end$/

## TEST: Teardown method generation when present
teardown_code = Tryouts::Teardown.new(
  code: "puts 'after all cleanup'",
  line_range: 10..10,
  path: 'test.rb'
)

teardown_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: teardown_code,
  source_file: 'cleanup_test.rb',
  metadata: {},
  warnings: []
)

teardown_generated = translator.generate_code(teardown_testrun)
#=~> /after\(:all\)/
#=~> /puts 'after all cleanup'/


## TEST: Multiple test cases generate multiple it blocks
test_case_2 = Tryouts::TestCase.new(
  description: "string length",
  code: "'test'.length",
  expectations: [Tryouts::Expectation.new(content: "4", type: :regular)],
  line_range: 3..4,
  path: 'test.rb',
  source_lines: ["'test'.length", "#=> 4"],
  first_expectation_line: 4
)

multi_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [@test_case_1, test_case_2],
  teardown: nil,
  source_file: 'string_test.rb',
  metadata: {},
  warnings: []
)

multi_code = translator.generate_code(multi_testrun)
multi_code.scan(/^  it "/).length
#=> 2
#==> multi_code.include?('it "string concatenation"')
#==> multi_code.include?('it "string length"')

## TEST: File basename is used in describe block
filename_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [@test_case_1],
  teardown: nil,
  source_file: 'custom_filename.rb',
  metadata: {},
  warnings: []
)

filename_code = translator.generate_code(filename_testrun)
filename_code.include?("RSpec.describe 'custom_filename' do")
#=> true

## TEST: Complex file paths are handled correctly
complex_filename_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [@test_case_1],
  teardown: nil,
  source_file: '/some/path/complex-test_file.spec.rb',
  metadata: {},
  warnings: []
)

complex_code = translator.generate_code(complex_filename_testrun)
complex_code.include?("RSpec.describe 'complex-test_file.spec' do")
#=> true

## TEST: Empty or nil descriptions are handled gracefully
empty_desc_case = Tryouts::TestCase.new(
  description: "",
  code: "nil.class",
  expectations: [Tryouts::Expectation.new(content: "NilClass", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["nil.class", "#=> NilClass"],
  first_expectation_line: 2
)

empty_desc_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [empty_desc_case],
  teardown: nil,
  source_file: 'empty_desc_test.rb',
  metadata: {},
  warnings: []
)

empty_desc_code = translator.generate_code(empty_desc_testrun)
# Should still generate an it block even with empty description
empty_desc_code.include?('it "" do')
#=> true

## TEST: Generated code ends with proper structure
simple_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [@test_case_1],
  teardown: nil,
  source_file: 'simple.rb',
  metadata: {},
  warnings: []
)

simple_code = translator.generate_code(simple_testrun)
# Should end with 'end' to close describe block
simple_code.strip.end_with?("end")
#=> true

## TEST: Multiple expectations in single test case
multi_expectation_case = Tryouts::TestCase.new(
  description: "multiple checks",
  code: "[1, 2, 3]",
  expectations: [
    Tryouts::Expectation.new(content: "[1, 2, 3]", type: :regular),
  ],
  line_range: 1..3,
  path: 'test.rb',
  source_lines: ["[1, 2, 3]", "#=> [1, 2, 3]"],
  first_expectation_line: 2
)

multi_exp_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [multi_expectation_case],
  teardown: nil,
  source_file: 'multi_exp.rb',
  metadata: {},
  warnings: []
)

multi_exp_code = translator.generate_code(multi_exp_testrun)
# Should contain expect statement
expect_count = multi_exp_code.scan(/expect\(result\)\.to eq/).length
expect_count
#=> 1

## TEST: Both setup and teardown present
full_setup_code = Tryouts::Setup.new(
  code: "@shared_var = 'initialized'",
  line_range: 1..1,
  path: 'test.rb'
)

full_teardown_code = Tryouts::Teardown.new(
  code: "@shared_var = nil",
  line_range: 10..10,
  path: 'test.rb'
)

full_testrun = Tryouts::Testrun.new(
  setup: full_setup_code,
  test_cases: [@test_case_1],
  teardown: full_teardown_code,
  source_file: 'full_test.rb',
  metadata: {},
  warnings: []
)

full_code = translator.generate_code(full_testrun)
has_before = full_code.include?("before(:all)")
has_after = full_code.include?("after(:all)")
has_both = has_before && has_after
has_both
#=> true

## TEST: Expectations that read _, error and elapsed_ms get them defined, as in direct mode
variables_case = Tryouts::TestCase.new(
  description: "the expectation variables",
  code: "2 + 2",
  expectations: [
    Tryouts::Expectation.new(content: "_ == 4", type: :true),
    Tryouts::Expectation.new(content: "error.nil?", type: :true),
    Tryouts::Expectation.new(content: "elapsed_ms < 1000", type: :true),
  ],
  line_range: 1..4,
  path: 'test.rb',
  source_lines: ["2 + 2", "#==> _ == 4", "#==> error.nil?", "#==> elapsed_ms < 1000"],
  first_expectation_line: 2
)
variables_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [variables_case],
  teardown: nil,
  source_file: 'variables_test.rb',
  metadata: {},
  warnings: []
)
translator.generate_code(variables_testrun)
#=~> /^    error = nil\n    started = Process\.clock_gettime\(Process::CLOCK_MONOTONIC\)\n    result = begin\n      2 \+ 2\n    end\n    elapsed_ms = \(\(Process\.clock_gettime\(Process::CLOCK_MONOTONIC\) - started\) \* 1000\)\.round\(2\)\n    _ = result$/

## TEST: A jump in an expectation is called inside a lambda, where it has a value
jump_case = Tryouts::TestCase.new(
  description: "next gives the value",
  code: "1",
  expectations: [Tryouts::Expectation.new(content: "next 1", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["1", "#=> next 1"],
  first_expectation_line: 2
)
jump_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [jump_case],
  teardown: nil,
  source_file: 'jump_test.rb',
  metadata: {},
  warnings: []
)
translator.generate_code(jump_testrun)
#=~> /^    expect\(result\)\.to eq\(-> \{ \(\n      next 1\n    \) \}\.call\)$/

## TEST: An exception expectation with a trailing comment is checked by its value, not its spelling
commented_case = Tryouts::TestCase.new(
  description: "invalid input",
  code: "Integer('twelve')",
  expectations: [Tryouts::Expectation.new(content: "ArgumentError # invalid input", type: :exception)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["Integer('twelve')", "#=!> ArgumentError # invalid input"],
  first_expectation_line: 2
)
commented_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [commented_case],
  teardown: nil,
  source_file: 'commented_test.rb',
  metadata: {},
  warnings: []
)
translator.generate_code(commented_testrun)
#=~> /^    expected = \(\n      ArgumentError # invalid input\n    \)\n    expect\(error\)\.not_to be_nil\n    if expected\.is_a\?\(Module\)\n      expect\(error\)\.to be_a\(expected\)\n    else\n      expect\(expected\)\.to be_truthy\n    end$/

## TEST: A non-nil expectation on a test that may raise also expects that nothing was raised
raised_case = Tryouts::TestCase.new(
  description: "raised, so not non-nil",
  code: "Integer('twelve')",
  expectations: [
    Tryouts::Expectation.new(content: "ArgumentError", type: :exception),
    Tryouts::Expectation.new(content: "", type: :non_nil),
  ],
  line_range: 1..3,
  path: 'test.rb',
  source_lines: ["Integer('twelve')", "#=!> ArgumentError", "#=*>"],
  first_expectation_line: 2
)
raised_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [raised_case],
  teardown: nil,
  source_file: 'raised_test.rb',
  metadata: {},
  warnings: []
)
translator.generate_code(raised_testrun)
#=~> /^    expect\(error\)\.to be_nil\n    expect\(result\)\.not_to be_nil$/
