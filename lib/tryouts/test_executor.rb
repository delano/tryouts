# lib/tryouts/test_executor.rb

require_relative 'test_batch'

class Tryouts
  class TestExecutor
    def initialize(file, testrun, options, output_manager, translator, global_tally)
      @file           = file
      @testrun        = testrun
      @options        = options
      @output_manager = output_manager
      @translator     = translator
      @global_tally   = global_tally

    end

    def execute
      @file_start = Time.now

      case @options[:framework]
      when :direct
        execute_direct_mode
      when :rspec
        execute_rspec_mode
      when :minitest
        execute_minitest_mode
      end
    end

    private


    def execute_direct_mode
      batch = TestBatch.new(
        @testrun,
        shared_context: @options[:shared_context],
        verbose: @options[:verbose],
        fails_only: @options[:fails_only],
        output_manager: @output_manager,
        global_tally: @global_tally,
      )

      # TestBatch handles file output, so don't duplicate it here
      unless @options[:verbose]
        context_mode = @options[:shared_context] ? 'shared' : 'fresh'
        @output_manager.file_execution_start(@file, @testrun.total_tests, context_mode)
      end

      test_results = []
      success      = batch.run do
        last_result = batch.results.last
        test_results << last_result if last_result
      end

      file_failed_count                 = test_results.count { |r| r.failed? }
      file_error_count                  = test_results.count { |r| r.error? }
      executed_test_count               = test_results.size

      # Note: Individual test results are added to the aggregator in TestBatch
      # Here we just update the file success count atomically
      if success
        @global_tally[:aggregator].increment_successful_files
      end

      duration = Time.now.to_f - @file_start.to_f
      @output_manager.file_success(@file, executed_test_count, file_failed_count, file_error_count, duration)

      # Combine failures and errors to determine the exit code.
      # If setup failed but no tests ran, still return 1 to indicate failure
      if success
        0
      else
        failure_count = file_failed_count + file_error_count
        failure_count > 0 ? failure_count : 1
      # TODO: If there was an error in the setup so no testcases ran, we still 
      # need to return a non-zero exit code otherwise test automation will 
      # consider it a successful run.
    end

    def execute_rspec_mode
      @output_manager.info 'Executing with RSpec framework', 2
      @translator.translate(@testrun)
      require 'rspec/core'
      RSpec::Core::Runner.run([])
      0
    end

    def execute_minitest_mode
      @output_manager.info 'Executing with Minitest framework', 2
      @translator.translate(@testrun)
      ARGV.clear
      require 'minitest/autorun'
      0
    end
  end
end
