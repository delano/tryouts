# lib/tryouts/test_executor.rb

require_relative 'testbatch'

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

      unless @options[:verbose]
        context_mode = @options[:shared_context] ? 'shared' : 'fresh'
        @output_manager.file_execution_start(@file, @testrun.total_tests, context_mode)
      end

      test_results = []
      success      = batch.run do
        last_result = batch.results.last
        test_results << last_result if last_result
      end

      file_failed_count                 = test_results.count { |r| r[:status] == :failed }
      file_error_count                  = test_results.count { |r| r[:status] == :error }
      @global_tally[:total_tests]      += batch.size
      @global_tally[:total_failed]     += file_failed_count
      @global_tally[:total_errors]     += file_error_count
      @global_tally[:successful_files] += 1 if success

      duration = Time.now - @file_start
      @output_manager.file_success(@file, batch.size, file_failed_count, file_error_count, duration)

      # Combine failures and errors to determine the exit code.
      success ? 0 : (file_failed_count + file_error_count)
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
