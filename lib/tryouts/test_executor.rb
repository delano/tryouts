# lib/tryouts/test_executor.rb
#
# frozen_string_literal: true

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
        line_spec: @options[:line_spec],  # Pass line_spec for output filtering
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

      file_failed_count   = test_results.count(&:failed?)
      file_error_count    = test_results.count(&:error?)
      executed_test_count = test_results.size
      not_run_count       = @testrun.total_tests - executed_test_count

      # Setup, interlude and teardown failures recorded for this file. Each
      # counts once toward the exit code, alongside the failing tests.
      aggregator       = @global_tally[:aggregator]
      section_failures = aggregator.infrastructure_failures_for(@file).map { |failure| failure[:type] }

      # NOTE: Individual test results are added to the aggregator in TestBatch
      # Here we just update the file success count atomically
      aggregator.increment_successful_files if success && section_failures.empty?
      aggregator.add_not_run(not_run_count)

      duration = Time.now.to_f - @file_start.to_f
      @output_manager.file_success(
        @file, executed_test_count, file_failed_count, file_error_count, duration,
        section_failures: section_failures, not_run: not_run_count
      )

      file_failed_count + file_error_count + section_failures.size
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
