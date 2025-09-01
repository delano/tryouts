# lib/tryouts/test_runner.rb

require 'concurrent'
require_relative 'parsers/legacy_parser'
require_relative 'parsers/enhanced_parser'
require_relative 'test_batch'
require_relative 'translators/rspec_translator'
require_relative 'translators/minitest_translator'
require_relative 'file_processor'
require_relative 'failure_collector'
require_relative 'test_result_aggregator'

class Tryouts
  class TestRunner
    FRAMEWORKS = {
      rspec: Translators::RSpecTranslator,
      minitest: Translators::MinitestTranslator,
    }.freeze

    FRAMEWORK_DEFAULTS = {
      direct: { shared_context: true, generate_only: false },
      rspec: { shared_context: false, generate_only: false },
      minitest: { shared_context: false, generate_only: false },
    }.freeze

    def initialize(files:, options:, output_manager:)
      @files           = files
      @options         = apply_framework_defaults(options)
      @output_manager  = output_manager
      @translator      = initialize_translator
      @global_tally    = initialize_global_tally
      @file_line_specs = options[:file_line_specs] || {}
    end

    def run
      log_run_info
      validate_framework

      result = process_files
      show_failure_summary
      # Always show grand total for agent mode to ensure output, otherwise only for multiple files
      if @options[:agent] || @global_tally[:aggregator].get_file_counts[:total] > 1
        show_grand_total
      end

      # For agent critical mode, only count errors as failures
      if @options[:agent] && ([:critical, 'critical'].include?(@options[:agent_focus]))
        # Include infrastructure failures as errors for agent critical mode
        display_errors        = @global_tally[:aggregator].get_display_counts[:errors]
        infrastructure_errors = @global_tally[:aggregator].infrastructure_failure_count
        display_errors + infrastructure_errors
      else
        result
      end
    end

    private

    def log_run_info
      @output_manager.processing_phase(@files.size)
      @output_manager.info "Framework: #{@options[:framework]}", 1
      @output_manager.info "Context: #{@options[:shared_context] ? 'shared' : 'fresh'}", 1

      @files.each_with_index do |file, idx|
        @output_manager.info "#{idx + 1}/#{@files.size}: #{Console.pretty_path(file)}", 1
      end
    end

    def apply_framework_defaults(options)
      framework_defaults = FRAMEWORK_DEFAULTS[options[:framework]] || {}
      framework_defaults.merge(options)
    end

    def validate_framework
      unless @options[:framework] == :direct || FRAMEWORKS.key?(@options[:framework])
        raise ArgumentError, "Unknown framework: #{@options[:framework]}. Available: #{FRAMEWORKS.keys.join(', ')}, direct"
      end
    end

    def initialize_translator
      return nil if @options[:framework] == :direct

      FRAMEWORKS[@options[:framework]].new
    end

    def initialize_global_tally
      {
        start_time: Time.now,
        aggregator: TestResultAggregator.new,
      }
    end

    def process_files
      if @options[:parallel] && @files.length > 1
        process_files_parallel
      else
        process_files_sequential
      end
    end

    def process_files_sequential
      failure_count = 0

      @files.each_with_index do |file, _idx|
        result         = process_file(file)
        failure_count += result unless result.zero?
        status         = result.zero? ? Console.color(:green, 'PASS') : Console.color(:red, 'FAIL')
        @output_manager.info "#{status} #{Console.pretty_path(file)} (#{result} failures)", 1
      end

      failure_count
    end

    def process_files_parallel
      # Determine thread pool size
      pool_size = @options[:parallel_threads] || Concurrent.processor_count
      @output_manager.info "Running #{@files.length} files in parallel (#{pool_size} threads)", 1

      # Create thread pool executor
      executor = Concurrent::ThreadPoolExecutor.new(
        min_threads: 1,
        max_threads: pool_size,
        max_queue: @files.length, # Queue size must accommodate all files
        fallback_policy: :abort, # Raise exception if pool and queue are exhausted
      )

      # Submit all file processing tasks to the thread pool
      futures = @files.map do |file|
        Concurrent::Future.execute(executor: executor) do
          process_file(file)
        end
      end

      # Wait for all tasks to complete and collect results
      failure_count = 0
      futures.each_with_index do |future, idx|
          result         = future.value # This blocks until the future completes
          failure_count += result unless result.zero?

          status = result.zero? ? Console.color(:green, 'PASS') : Console.color(:red, 'FAIL')
          file   = @files[idx]
          @output_manager.info "#{status} #{Console.pretty_path(file)} (#{result} failures)", 1
      rescue StandardError => ex
          failure_count += 1
          file           = @files[idx]
          @output_manager.info "#{Console.color(:red, 'ERROR')} #{Console.pretty_path(file)} (#{ex.message})", 1
      end

      # Shutdown the thread pool
      executor.shutdown
      executor.wait_for_termination(10) # Wait up to 10 seconds for clean shutdown

      failure_count
    end

    def process_file(file)
      # Pass line spec for this file if available
      file_options = @options.dup
      if @file_line_specs && @file_line_specs[file]
        file_options[:line_spec] = @file_line_specs[file]
      end

      processor = FileProcessor.new(
        file: file,
        options: file_options,
        output_manager: @output_manager,
        translator: @translator,
        global_tally: @global_tally,
      )
      processor.process
    rescue StandardError => ex
      handle_file_error(ex)
      @global_tally[:aggregator].add_infrastructure_failure(
        :file_processing, file, ex.message, ex
      )
      1
    end

    def show_failure_summary
      # Show failure summary if any failures exist
      aggregator = @global_tally[:aggregator]
      if aggregator.any_display_failures?
        @output_manager.batch_summary(aggregator.failure_collector)
      end
    end

    def show_grand_total
      elapsed_time   = Time.now - @global_tally[:start_time]
      aggregator     = @global_tally[:aggregator]
      display_counts = aggregator.get_display_counts
      file_counts    = aggregator.get_file_counts

      @output_manager.grand_total(
        display_counts[:total_tests],
        display_counts[:failed],
        display_counts[:errors],
        file_counts[:successful],
        file_counts[:total],
        elapsed_time,
      )
    end

    def handle_file_error(exception)
      @status       = :error
      Tryouts.debug "TestRunner#process_file: An error occurred processing #{file}: #{ex.message}"
      error_message = "Batch execution failed: #{exception.message}"
      backtrace     = exception.respond_to?(:backtrace) ? exception.backtrace : nil

      @output_manager&.error(error_message, backtrace)
    end
  end
end
