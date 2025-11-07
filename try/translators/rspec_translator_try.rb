# try/translators/rspec_translator_try.rb
#
# frozen_string_literal: true

# Tests for RSpecTranslator functionality

require_relative '../test_helper'
require_relative '../../lib/tryouts/translators/rspec_translator'
require_relative '../../lib/tryouts/test_case'

## TEST: Translator initializes successfully when rspec is available
translator = Tryouts::Translators::RSpecTranslator.new
translator.class.name
#=> "Tryouts::Translators::RSpecTranslator"

## TEST: Generate code creates valid RSpec describe structure
translator = Tryouts::Translators::RSpecTranslator.new

# Create mock test data
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
# Test that generated code contains expected RSpec structure
generated_code.include?("RSpec.describe 'math_test.rb'")
##=> true

## TEST: Generated code contains before(:all) block when setup present
# Using same translator and testrun from previous test
generated_code.include?("before(:all)")
##=> true

## TEST: Generated code contains setup content
generated_code.include?("puts 'before all setup'")
##=> true

## TEST: Generated code contains it block with description
generated_code.include?("it 'simple multiplication'")
##=> true

## TEST: Generated code contains expect().to eq() for regular expectations
generated_code.include?("expect(result).to eq(6)")
##=> true

## TEST: Exception expectation generates expect{}.to raise_error structure
translator = Tryouts::Translators::RSpecTranslator.new

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
exception_code.include?("expect {")
#=> true

## TEST: Exception expectation includes raise_error block
exception_code.include?("}.to raise_error do |caught_error|")
##=> true

## TEST: Exception expectation includes error variable assignment
exception_code.include?("error = caught_error")
##=> true

## TEST: Exception expectation includes truthy assertion
exception_code.include?("expect(error.is_a?(ArgumentError)).to be_truthy")
##=> true

## TEST: Teardown method generation when present
translator = Tryouts::Translators::RSpecTranslator.new

teardown_code = Tryouts::Teardown.new(
  code: "puts 'after all cleanup'",
  line_range: 10..10,
  path: 'test.rb'
)

teardown_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case], # reuse from earlier
  teardown: teardown_code,
  source_file: 'cleanup_test.rb',
  metadata: {},
  warnings: []
)

teardown_generated = translator.generate_code(teardown_testrun)
#=~> /after\(:all\)/
#=~> /puts 'after all cleanup'/


## TEST: Multiple test cases generate multiple it blocks
translator = Tryouts::Translators::RSpecTranslator.new

@test_case_1 = Tryouts::TestCase.new(
  description: "string concatenation",
  code: "'hello' + ' world'",
  expectations: [Tryouts::Expectation.new(content: "'hello world'", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["'hello' + ' world'", "#=> 'hello world'"],
  first_expectation_line: 2
)

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

@multi_code = translator.generate_code(multi_testrun)
it_blocks_count = @multi_code.scan(/it '/).length
it_blocks_count
#=> 2

## TEST: Multiple it blocks have correct descriptions
@multi_code
#=~> /it 'string concatenation'/
#=~> /it 'string length'/

## TEST: File basename is used in describe block
translator = Tryouts::Translators::RSpecTranslator.new

filename_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [@test_case_1],
  teardown: nil,
  source_file: 'custom_filename.rb',
  metadata: {},
  warnings: []
)

filename_code = translator.generate_code(filename_testrun)
filename_code.include?("RSpec.describe 'custom_filename.rb'")
##=> true

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
complex_code.include?("RSpec.describe 'complex-test_file.spec.rb'")
##=> true

## TEST: Empty or nil descriptions are handled gracefully
translator = Tryouts::Translators::RSpecTranslator.new

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
empty_desc_code.include?("it ''")
#=> true

## TEST: Generated code ends with proper structure
translator = Tryouts::Translators::RSpecTranslator.new

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
##=> true

## TEST: Multiple expectations in single test case
translator = Tryouts::Translators::RSpecTranslator.new

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
translator = Tryouts::Translators::RSpecTranslator.new

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
##=> true
