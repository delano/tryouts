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
@test_case = Tryouts::TestCase.new(
  description: 'test description',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@result_packet = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@entry = Tryouts::FailureCollector::FailureEntry.new('test.rb', @test_case, @result_packet)
@entry.line_number
#=> 7

## TEST: FailureEntry can format descriptions
@test_case_with_desc = Tryouts::TestCase.new(
  description: 'TEST: A failing test',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@result_packet_with_desc = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_with_desc,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@entry_with_desc = Tryouts::FailureCollector::FailureEntry.new('test.rb', @test_case_with_desc, @result_packet_with_desc)
@entry_with_desc.description
#=> "TEST: A failing test"

## TEST: FailureEntry handles empty descriptions
@test_case_empty = Tryouts::TestCase.new(
  description: '',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@result_packet_empty = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_empty,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@entry_empty = Tryouts::FailureCollector::FailureEntry.new('test.rb', @test_case_empty, @result_packet_empty)
@entry_empty.description
#=> "unnamed test"

## TEST: FailureEntry can format failure reasons for regular failures
@test_case_failure = Tryouts::TestCase.new(
  description: 'test',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@result_packet_failure = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_failure,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@entry_failure = Tryouts::FailureCollector::FailureEntry.new('test.rb', @test_case_failure, @result_packet_failure)
@entry_failure.failure_reason
#=> "expected 3, got 2"

## TEST: FailureEntry can format error reasons
@test_case_error = Tryouts::TestCase.new(
  description: 'test',
  code: '1 / 0',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 / 0'],
  first_expectation_line: 7,
)
@error = ZeroDivisionError.new('divided by 0')
@result_packet_error = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_error,
  status: :error,
  result_value: nil,
  actual_results: [],
  expected_results: [],
  error: @error,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@entry_error = Tryouts::FailureCollector::FailureEntry.new('test.rb', @test_case_error, @result_packet_error)
@entry_error.failure_reason
#=> "ZeroDivisionError: divided by 0"

## TEST: FailureCollector can add failures
@collector = Tryouts::FailureCollector.new
@test_case_add = Tryouts::TestCase.new(
  description: 'test',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@result_packet_add = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_add,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@collector.add_failure('test.rb', @result_packet_add)
@collector.any_failures?
#=> true

## TEST: FailureCollector tracks failure counts correctly
@collector_counts = Tryouts::FailureCollector.new
@test_case_counts = Tryouts::TestCase.new(
  description: 'test',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'test.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@failed_result = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_counts,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@error_result = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case_counts,
  status: :error,
  result_value: nil,
  actual_results: [],
  expected_results: [],
  error: StandardError.new('test error'),
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@collector_counts.add_failure('test.rb', @failed_result)
@collector_counts.add_failure('test.rb', @error_result)
[@collector_counts.failure_count, @collector_counts.error_count, @collector_counts.total_issues]
#=> [1, 1, 2]

## TEST: FailureCollector groups failures by file
@collector_files = Tryouts::FailureCollector.new
@test_case1 = Tryouts::TestCase.new(
  description: 'test1',
  code: '1 + 1',
  expectations: [],
  line_range: (5..7),
  path: 'file1.rb',
  source_lines: ['1 + 1'],
  first_expectation_line: 7,
)
@test_case2 = Tryouts::TestCase.new(
  description: 'test2',
  code: '2 + 2',
  expectations: [],
  line_range: (10..12),
  path: 'file2.rb',
  source_lines: ['2 + 2'],
  first_expectation_line: 12,
)
@result1 = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case1,
  status: :failed,
  result_value: 2,
  actual_results: [2],
  expected_results: [3],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@result2 = Tryouts::TestCaseResultPacket.new(
  test_case: @test_case2,
  status: :failed,
  result_value: 4,
  actual_results: [4],
  expected_results: [5],
  error: nil,
  captured_output: '',
  elapsed_time: 0.001,
  metadata: {},
)
@collector_files.add_failure('file1.rb', @result1)
@collector_files.add_failure('file2.rb', @result2)
@collector_files.failures_by_file.keys.sort
#=> ["file1.rb", "file2.rb"]
