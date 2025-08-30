# try/core/concurrency_try.rb
# Tests for thread safety and atomic operations in TestResultAggregator

require_relative '../../lib/tryouts/test_result_aggregator'

# Setup: Create mock test case and result packet classes
class MockTestCase
  attr_reader :description, :line_range, :path
  def initialize(description, line_range = 1..1, path = "concurrent_test.rb")
    @description = description
    @line_range = line_range
    @path = path
  end
end

class MockResultPacket
  attr_reader :test_case, :status, :result_value, :actual_results, :expected_results, :error

  def initialize(status)
    @test_case = MockTestCase.new("concurrent test case")
    @status = status
    @result_value = nil
    @actual_results = []
    @expected_results = []
    @error = nil
  end

  def passed?; @status == :passed; end
  def failed?; @status == :failed; end
  def error?; @status == :error; end
end

puts 'Concurrency test setup complete'

## TEST 1: Atomic increment methods prevent race conditions
@aggregator = Tryouts::TestResultAggregator.new

# Create 50 threads, each incrementing counters 20 times
threads = []
50.times do |i|
  threads << Thread.new do
    20.times do
      @aggregator.increment_total_files
      @aggregator.increment_successful_files if i.even?
    end
  end
end

threads.each(&:join)

@file_counts = @aggregator.get_file_counts
## Test file count tracking
@file_counts[:total]
#=> 1000

## Test successful file count
@file_counts[:successful]
#=> 500

## TEST 2: Concurrent test result processing maintains accuracy
@aggregator2 = Tryouts::TestResultAggregator.new

# Process test results from multiple threads
threads = []
25.times do |i|
  threads << Thread.new do
    # Each thread processes 4 passed, 4 failed, 4 error results
    4.times do
      @aggregator2.add_test_result("file_#{i}", MockResultPacket.new(:passed))
      @aggregator2.add_test_result("file_#{i}", MockResultPacket.new(:failed))
      @aggregator2.add_test_result("file_#{i}", MockResultPacket.new(:error))
    end
  end
end

threads.each(&:join)

@display_counts = @aggregator2.get_display_counts
@display_counts[:total_tests]
#=> 300

## Test passed count
@display_counts[:passed]
#=> 100

## Test failed count
@display_counts[:failed]
#=> 100

## Test error count
@display_counts[:errors]
#=> 100

## TEST 3: Infrastructure failure tracking is thread-safe
@aggregator3 = Tryouts::TestResultAggregator.new

threads = []
20.times do |i|
  threads << Thread.new do
    5.times do |j|
      @aggregator3.add_infrastructure_failure(
        :setup,
        "file_#{i}_#{j}.rb",
        "Setup failed in thread #{i}",
        StandardError.new("concurrent error")
      )
    end
  end
end

threads.each(&:join)

@infrastructure_failures = @aggregator3.get_infrastructure_failures
@infrastructure_failures.size
#=> 100

## TEST 4: Mixed concurrent operations maintain consistency
@aggregator4 = Tryouts::TestResultAggregator.new

threads = []
10.times do |i|
  threads << Thread.new do
    # Mix different types of operations
    @aggregator4.increment_total_files
    @aggregator4.add_test_result("mixed_#{i}", MockResultPacket.new(:passed))
    @aggregator4.add_infrastructure_failure(:teardown, "mixed_#{i}.rb", "teardown error")
    @aggregator4.increment_successful_files
    @aggregator4.add_test_result("mixed_#{i}", MockResultPacket.new(:failed))
  end
end

threads.each(&:join)

@mixed_file_counts = @aggregator4.get_file_counts
@mixed_display_counts = @aggregator4.get_display_counts
@mixed_infrastructure_failures = @aggregator4.get_infrastructure_failures

# Verify all counts are consistent
@mixed_file_counts[:total]
#=> 10

## Test mixed successful count
@mixed_file_counts[:successful]
#=> 10

## Test mixed total tests count
@mixed_display_counts[:total_tests]
#=> 20

## Test mixed passed count
@mixed_display_counts[:passed]
#=> 10

## Test mixed failed count
@mixed_display_counts[:failed]
#=> 10

## Test mixed infrastructure failure count
@mixed_infrastructure_failures.size
#=> 10

## TEST 5: Aggregator summary works correctly with concurrent data
@summary = @aggregator4.summary
@summary
#=~> /10 passed, 10 failed, 10 infrastructure failures/

puts 'All concurrency tests completed successfully'
