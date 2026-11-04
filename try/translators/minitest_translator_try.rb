# try/translators/minitest_translator_try.rb
#
# frozen_string_literal: true

# Tests for MinitestTranslator functionality

require_relative '../test_helper'
require_relative '../../lib/tryouts/translators/minitest_translator'
require_relative '../../lib/tryouts/test_case'

## TEST: Translator initializes successfully when minitest is available
translator = Tryouts::Translators::MinitestTranslator.new
translator.class.name
#=> "Tryouts::Translators::MinitestTranslator"

## TEST: Method name parameterization handles spaces and special chars
test_description = "Simple Math Test with Spaces!"
Tryouts::Translators::MinitestTranslator.parameterize(test_description)
#=> "simple_math_test_with_spaces"

## TEST: Method name parameterization handles edge cases
edge_case = "  __test--with__special___chars  "
Tryouts::Translators::MinitestTranslator.parameterize(edge_case)
#=> "test_with_special_chars"

## TEST: Generate code creates valid Minitest structure for basic test
translator = Tryouts::Translators::MinitestTranslator.new
test_case = Tryouts::TestCase.new(
  description: "simple addition",
  code: "puts 'hello'",
  expectations: [Tryouts::Expectation.new(content: "2", type: :regular)],
  line_range: 2..3,
  path: 'test.rb',
  source_lines: ["puts 'hello'", "#=> 2"],
  first_expectation_line: 3
)
testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'basic_test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
generated_code.include?("class Testbasictest < Minitest::Test")
#=> true

## TEST: Generated code contains test method for single test case
translator = Tryouts::Translators::MinitestTranslator.new
test_case = Tryouts::TestCase.new(
  description: "simple addition",
  code: "puts 'hello'",
  expectations: [Tryouts::Expectation.new(content: "2", type: :regular)],
  line_range: 2..3,
  path: 'test.rb',
  source_lines: ["puts 'hello'", "#=> 2"],
  first_expectation_line: 3
)
testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
generated_code.include?("def test_000_simple_addition")
#=> true

## TEST: Generated code contains assert_equal for regular expectations
translator = Tryouts::Translators::MinitestTranslator.new
test_case = Tryouts::TestCase.new(
  description: "math test",
  code: "puts 'math'",
  expectations: [Tryouts::Expectation.new(content: "6", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["puts 'math'", "#=> 6"],
  first_expectation_line: 2
)
testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
generated_code
#=~> /^    assert_equal\(\(\n      6\n    \), result\)$/

## TEST: Generated code includes required minitest imports
translator = Tryouts::Translators::MinitestTranslator.new
test_case = Tryouts::TestCase.new(
  description: "simple test",
  code: "puts 'test'",
  expectations: [Tryouts::Expectation.new(content: "true", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["puts 'test'", "#=> true"],
  first_expectation_line: 2
)
testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
has_minitest_require = generated_code.include?("require 'minitest/test'")
has_autorun_require = generated_code.include?("require 'minitest/autorun'")
has_minitest_require && has_autorun_require
#=> true

## TEST: Setup code generation when present
translator = Tryouts::Translators::MinitestTranslator.new
setup_code = Tryouts::Setup.new(
  code: "puts 'setup runs'",
  line_range: 1..1,
  path: 'test.rb'
)
test_case = Tryouts::TestCase.new(
  description: "with setup",
  code: "puts 'with setup'",
  expectations: [Tryouts::Expectation.new(content: "2", type: :regular)],
  line_range: 2..3,
  path: 'test.rb',
  source_lines: ["puts 'with setup'", "#=> 2"],
  first_expectation_line: 3
)
testrun = Tryouts::Testrun.new(
  setup: setup_code,
  test_cases: [test_case],
  teardown: nil,
  source_file: 'setup_test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
has_setup_method = generated_code.include?("def setup")
has_setup_content = generated_code.include?("puts 'setup runs'")
has_setup_method && has_setup_content
#=> true

## TEST: Teardown code generation when present
translator = Tryouts::Translators::MinitestTranslator.new
teardown_code = Tryouts::Teardown.new(
  code: "puts 'cleanup'",
  line_range: 10..10,
  path: 'test.rb'
)
test_case = Tryouts::TestCase.new(
  description: "with teardown",
  code: "puts 'teardown'",
  expectations: [Tryouts::Expectation.new(content: "2", type: :regular)],
  line_range: 2..3,
  path: 'test.rb',
  source_lines: ["puts 'teardown'", "#=> 2"],
  first_expectation_line: 3
)
testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case],
  teardown: teardown_code,
  source_file: 'teardown_test.rb',
  metadata: {},
  warnings: []
)
generated_code = translator.generate_code(testrun)
has_teardown_method = generated_code.include?("def teardown")
has_teardown_content = generated_code.include?("puts 'cleanup'")
has_teardown_method && has_teardown_content
#=> true

## TEST: Exception expectation rescues the error and asserts on it
translator = Tryouts::Translators::MinitestTranslator.new
exception_test_case = Tryouts::TestCase.new(
  description: "division by zero",
  code: "puts 'exception test'",
  expectations: [Tryouts::Expectation.new(content: "error.is_a?(ZeroDivisionError)", type: :exception)],
  line_range: 4..5,
  path: 'test.rb',
  source_lines: ["puts 'exception test'", "#=!> error.is_a?(ZeroDivisionError)"],
  first_expectation_line: 5
)
exception_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [exception_test_case],
  teardown: nil,
  source_file: 'exception_test.rb',
  metadata: {},
  warnings: []
)
exception_code = translator.generate_code(exception_testrun)
exception_code
#=~> /^    rescue Exception => error\n      raise if error\.is_a\?\(SignalException\) \|\| error\.is_a\?\(SystemExit\)$/
#=~> /^    refute_nil error\n    ->\(expected\) do\n      if expected\.is_a\?\(Module\)\n        assert_kind_of expected, error\n      else\n        assert expected\n      end\n    end\.call\(\(\n      error\.is_a\?\(ZeroDivisionError\)\n    \)\)$/

## TEST: Multiple test cases generate multiple methods with proper indexing
translator = Tryouts::Translators::MinitestTranslator.new
test_case_1 = Tryouts::TestCase.new(
  description: "first test",
  code: "2 + 2",
  expectations: [Tryouts::Expectation.new(content: "4", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["2 + 2", "#=> 4"],
  first_expectation_line: 2
)
test_case_2 = Tryouts::TestCase.new(
  description: "second test",
  code: "3 * 3",
  expectations: [Tryouts::Expectation.new(content: "9", type: :regular)],
  line_range: 3..4,
  path: 'test.rb',
  source_lines: ["3 * 3", "#=> 9"],
  first_expectation_line: 4
)
multi_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [test_case_1, test_case_2],
  teardown: nil,
  source_file: 'multi_test.rb',
  metadata: {},
  warnings: []
)
multi_code = translator.generate_code(multi_testrun)
test_methods_count = multi_code.scan(/def test_\d+_/).length
has_first_method = multi_code.include?("def test_000_first_test")
has_second_method = multi_code.include?("def test_001_second_test")
test_methods_count == 2 && has_first_method && has_second_method
#=> true

## TEST: Complex filename generates clean class name
translator = Tryouts::Translators::MinitestTranslator.new
simple_case = Tryouts::TestCase.new(
  description: "test case",
  code: "puts 'complex'",
  expectations: [Tryouts::Expectation.new(content: "2", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["puts 'complex'", "#=> 2"],
  first_expectation_line: 2
)
complex_filename_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [simple_case],
  teardown: nil,
  source_file: 'complex-file_name.try.rb',
  metadata: {},
  warnings: []
)
complex_code = translator.generate_code(complex_filename_testrun)
# Special characters should be stripped from class name - checking actual output
complex_code.include?("class Testcomplexfilenametry < Minitest::Test")
#=> true

## TEST: Empty descriptions are handled gracefully
translator = Tryouts::Translators::MinitestTranslator.new
empty_desc_case = Tryouts::TestCase.new(
  description: "",
  code: "true",
  expectations: [Tryouts::Expectation.new(content: "true", type: :regular)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["true", "#=> true"],
  first_expectation_line: 2
)
empty_desc_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [empty_desc_case],
  teardown: nil,
  source_file: 'empty_test.rb',
  metadata: {},
  warnings: []
)
empty_desc_code = translator.generate_code(empty_desc_testrun)
# Should still generate a test method even with empty description
empty_desc_code.include?("def test_000_")
#=> true

## TEST: Translate builds a live Minitest class with test methods
translator = Tryouts::Translators::MinitestTranslator.new
live_case = Tryouts::TestCase.new(
  description: "adds two numbers",
  code: "2 + 2",
  expectations: [Tryouts::Expectation.new(content: "4", type: :regular)],
  line_range: 1..2,
  path: 'live_translate.rb',
  source_lines: ["2 + 2", "#=> 4"],
  first_expectation_line: 2
)
live_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [live_case],
  teardown: nil,
  source_file: 'live_translate.rb',
  metadata: {},
  warnings: []
)
live_class = translator.translate(live_testrun)
live_class.instance_methods(false).grep(/^test_/).map(&:to_s)
#=> ["test_000_adds_two_numbers"]

## TEST: Expectations that read _, error and elapsed_ms get them defined, as in direct mode
translator = Tryouts::Translators::MinitestTranslator.new
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
variables_code = translator.generate_code(variables_testrun)
variables_code
#=~> /^    error = nil\n    started = Process\.clock_gettime\(Process::CLOCK_MONOTONIC\)\n    result = begin\n      2 \+ 2\n    end\n    elapsed_ms = \(\(Process\.clock_gettime\(Process::CLOCK_MONOTONIC\) - started\) \* 1000\)\.round\(2\)\n    _ = result$/

## TEST: A test whose expectations read none of them defines none of them
translator = Tryouts::Translators::MinitestTranslator.new
plain_case = Tryouts::TestCase.new(
  description: "a plain sum",
  code: "2 + 2",
  expectations: [Tryouts::Expectation.new(content: "result == 4", type: :true)],
  line_range: 1..2,
  path: 'test.rb',
  source_lines: ["2 + 2", "#==> result == 4"],
  first_expectation_line: 2
)
plain_testrun = Tryouts::Testrun.new(
  setup: nil,
  test_cases: [plain_case],
  teardown: nil,
  source_file: 'plain_test.rb',
  metadata: {},
  warnings: []
)
translator.generate_code(plain_testrun).lines.grep(/error = nil|elapsed_ms|_ = result/)
#=> []

## TEST: A jump in an expectation is called inside a lambda, where it has a value
translator = Tryouts::Translators::MinitestTranslator.new
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
#=~> /^    assert_equal\(-> \{ \(\n      next 1\n    \) \}\.call, result\)$/

## TEST: An exception expectation with a trailing comment is checked by its value, not its spelling
translator = Tryouts::Translators::MinitestTranslator.new
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
#=~> /^    refute_nil error\n    ->\(expected\) do\n      if expected\.is_a\?\(Module\)\n        assert_kind_of expected, error\n      else\n        assert expected\n      end\n    end\.call\(\(\n      ArgumentError # invalid input\n    \)\)$/

## TEST: A non-nil expectation on a test that may raise also asserts that nothing was raised
translator = Tryouts::Translators::MinitestTranslator.new
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
#=~> /^    assert_nil error\n    refute_nil result$/
