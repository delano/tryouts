# try/formatters/failure_summary_try.rb

## TEST: FailureCollector can be created
collector = Tryouts::FailureCollector.new
collector.class
#=> Tryouts::FailureCollector

## TEST: FailureCollector starts empty
collector = Tryouts::FailureCollector.new
collector.any_failures?
#=> false

## TEST: FailureCollector counts are zero when empty
collector = Tryouts::FailureCollector.new
[collector.failure_count, collector.error_count, collector.total_issues]
#=> [0, 0, 0]

## TEST: FailureEntry can format line numbers
test_case = Tryouts::TestCase.new(
  description: "test description",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
entry = Tryouts::FailureCollector::FailureEntry.new("test.rb", test_case, result_packet)
entry.line_number
#=> 7

## TEST: FailureEntry can format descriptions
test_case = Tryouts::TestCase.new(
  description: "TEST: A failing test",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
entry = Tryouts::FailureCollector::FailureEntry.new("test.rb", test_case, result_packet)
entry.description
#=> "TEST: A failing test"

## TEST: FailureEntry handles empty descriptions
test_case = Tryouts::TestCase.new(
  description: "",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
entry = Tryouts::FailureCollector::FailureEntry.new("test.rb", test_case, result_packet)
entry.description
#=> "unnamed test"

## TEST: FailureEntry can format failure reasons for regular failures
test_case = Tryouts::TestCase.new(
  description: "test",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
entry = Tryouts::FailureCollector::FailureEntry.new("test.rb", test_case, result_packet)
entry.failure_reason
#=> "expected 3, got 2"

## TEST: FailureEntry can format error reasons
test_case = Tryouts::TestCase.new(
  description: "test",
  code: "1 / 0",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 / 0"],
  first_expectation_line: 7
)
error = ZeroDivisionError.new("divided by 0")
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :error,
  result_value: nil,
  actual_results: [],
  expected_results: [],
  error: error,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
entry = Tryouts::FailureCollector::FailureEntry.new("test.rb", test_case, result_packet)
entry.failure_reason
#=> "ZeroDivisionError: divided by 0"

## TEST: FailureCollector can add failures
collector = Tryouts::FailureCollector.new
test_case = Tryouts::TestCase.new(
  description: "test",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
collector.add_failure("test.rb", result_packet)
collector.any_failures?
#=> true

## TEST: FailureCollector tracks failure counts correctly
collector = Tryouts::FailureCollector.new
test_case = Tryouts::TestCase.new(
  description: "test",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "test.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
failed_result = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
error_result = Tryouts::TestCaseResultPacket.new(
  test_case: test_case,
  status: :error,
  result_value: nil,
  actual_results: [],
  expected_results: [],
  error: StandardError.new("test error"),
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
collector.add_failure("test.rb", failed_result)
collector.add_failure("test.rb", error_result)
[collector.failure_count, collector.error_count, collector.total_issues]
#=> [1, 1, 2]

## TEST: FailureCollector groups failures by file
collector = Tryouts::FailureCollector.new
test_case1 = Tryouts::TestCase.new(
  description: "test1",
  code: "1 + 1",
  expectations: [],
  line_range: (5..7),
  path: "file1.rb",
  source_lines: ["1 + 1"],
  first_expectation_line: 7
)
test_case2 = Tryouts::TestCase.new(
  description: "test2",
  code: "2 + 2",
  expectations: [],
  line_range: (10..12),
  path: "file2.rb",
  source_lines: ["2 + 2"],
  first_expectation_line: 12
)
result1 = Tryouts::TestCaseResultPacket.new(
  test_case: test_case1,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
result2 = Tryouts::TestCaseResultPacket.new(
  test_case: test_case2,
  status: :failed,
  result_value: 4,
  actual_results: [4],
  expected_results: [5],
  error: nil,
  captured_output: "",
  elapsed_time: 0.001,
  metadata: {}
)
collector.add_failure("file1.rb", result1)
collector.add_failure("file2.rb", result2)
collector.failures_by_file.keys.sort
#=> ["file1.rb", "file2.rb"]
