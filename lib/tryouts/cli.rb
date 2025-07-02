# lib/tryouts/cli.rb

require 'optparse'

require_relative 'cli/opts'
require_relative 'cli/formatters'

require_relative 'prism_parser'
require_relative 'testbatch'
require_relative 'translators/rspec_translator'
require_relative 'translators/minitest_translator'

class Tryouts
  class CLI
    FRAMEWORKS = {
      rspec: Translators::RSpecTranslator,
      minitest: Translators::MinitestTranslator,
    }.freeze

    # Framework defaults - very clear configuration
    FRAMEWORK_DEFAULTS = {
      direct: {
        shared_context: true,   # Direct mode uses shared context by default
        generate_only: false,
      },
      rspec: {
        shared_context: false,  # Framework modes use fresh context
        generate_only: false,
      },
      minitest: {
        shared_context: false,  # Framework modes use fresh context
        generate_only: false,
      },
    }.freeze

    def initialize
      @options = {
        framework: :direct,     # Direct is now the default
        verbose: false,
        inspect: false,
      }
      @output_manager = nil
    end

    def run(files, **options)
      @options.merge!(options)

      # Initialize output manager with appropriate formatter
      @output_manager = FormatterFactory.create_output_manager(@options)

      @output_manager.processing_phase(files.size)
      @output_manager.info "Framework: #{@options[:framework] || :direct}", 1
      @output_manager.info "Context: #{@options[:shared_context] ? 'shared' : 'fresh'}", 1

      files.each_with_index do |file, idx|
        @output_manager.info "#{idx + 1}/#{files.size}: #{Console.pretty_path(file)}", 1
      end

      handle_version_flag(@options)

      # Validate all files exist before processing
      validate_files_exist(files)

      final_options = apply_framework_defaults(@options)
      validate_framework(final_options)
      translator    = initialize_translator(final_options)
      global_tally  = initialize_global_tally

      # Process all files
      result = process_files(files, final_options, global_tally, translator)

      show_grand_total(global_tally, final_options) if global_tally[:file_count] > 1

      result
    end

    private

    def validate_files_exist(files)
      missing_files = files.reject { |file| File.exist?(file) }

      unless missing_files.empty?
        missing_files.each { |file| @output_manager.error("File not found: #{file}") }
        exit 1
      end
    end

    def process_files(files, final_options, global_tally, translator)
      count = 0 # Number of files with errors

      files.each do |file|
        result = process_file(file, final_options, global_tally, translator)
        count += result unless result.zero?
        status = result.zero? ? Console.color(:green, "PASS") : Console.color(:red, "FAIL")
        @output_manager.info "#{status} #{Console.pretty_path(file)} (#{result} failures)", 1
      end

      count
    end

    def handle_version_flag(options)
      return unless options[:version]

      @output_manager.raw("Tryouts version #{Tryouts::VERSION}")
      exit 0
    end

    def apply_framework_defaults(options)
      framework_defaults = FRAMEWORK_DEFAULTS[options[:framework]] || {}
      final_options      = framework_defaults.merge(options)
        # Framework info already logged in run method
      final_options
    end

    def validate_framework(final_options)
      unless final_options[:framework] == :direct || FRAMEWORKS.key?(final_options[:framework])
        raise ArgumentError, "Unknown framework: #{final_options[:framework]}. Available: #{FRAMEWORKS.keys.join(', ')}, direct"
      end
    end

    def initialize_translator(final_options)
      translator = FRAMEWORKS[final_options[:framework]].new unless final_options[:framework] == :direct
      translator
    end

    def initialize_global_tally
      {
        total_tests: 0,
        total_failed: 0,
        file_count: 0,
        start_time: Time.now,
        successful_files: 0,
      }
    end

    def process_file(file, final_options, global_tally, translator)
      begin
        testrun                    = PrismParser.new(file).parse
        global_tally[:file_count] += 1
        @output_manager.file_parsed(file, testrun.total_tests)

        if final_options[:inspect]
          handle_inspect_mode(file, testrun, final_options, translator)
        elsif final_options[:generate_only]
          handle_generate_only_mode(file, testrun, final_options, translator)
        else
          execute_tests(file, testrun, final_options, global_tally, translator)
        end
      rescue TryoutSyntaxError => ex
        handle_syntax_error(file, ex)
      rescue StandardError => ex
        handle_general_error(file, ex, final_options)
      else
        0
      end

    rescue Timeout::Error, SystemExit => ex
      handle_timeout_error(file, ex)

    rescue SystemStackError, LoadError => ex
      handle_general_error(file, ex, final_options)
    end

    def handle_inspect_mode(file, testrun, final_options, _translator)
      @output_manager.raw("Inspecting: #{file}")
      @output_manager.separator(:heavy)
      @output_manager.raw("Found #{testrun.total_tests} test cases")
      @output_manager.raw("Setup code: #{testrun.setup.empty? ? 'None' : 'Present'}")
      @output_manager.raw("Teardown code: #{testrun.teardown.empty? ? 'None' : 'Present'}")
      @output_manager.raw("")

      testrun.test_cases.each_with_index do |tc, i|
        @output_manager.raw("Test #{i + 1}: #{tc.description}")
        @output_manager.raw("  Code lines: #{tc.code.lines.count}")
        @output_manager.raw("  Expectations: #{tc.expectations.size}")
        @output_manager.raw("  Range: #{tc.line_range}")
        @output_manager.raw("")
      end

      return unless final_options[:framework] != :direct

      @output_manager.raw("Testing #{final_options[:framework]} translation...")
      framework_klass    = FRAMEWORKS[final_options[:framework]]
      inspect_translator = framework_klass.new

      translated_code = inspect_translator.generate_code(testrun)
      @output_manager.raw("#{final_options[:framework].to_s.capitalize} code generated (#{translated_code.lines.count} lines)")
      @output_manager.raw("")
    end

    def handle_generate_only_mode(file, testrun, final_options, translator)
      @output_manager.raw("# Generated #{final_options[:framework]} code for #{file}")
      @output_manager.raw("# Updated: #{Time.now}")
      @output_manager.raw(translator.generate_code(testrun))
      @output_manager.raw("")
    end

    def execute_tests(file, testrun, final_options, global_tally, translator)
      file_start = Time.now
      case final_options[:framework]
      when :direct
        batch = TestBatch.new(
          testrun,
          shared_context: final_options[:shared_context],
          verbose: final_options[:verbose],
          fails_only: final_options[:fails_only],
          output_manager: @output_manager,
        )

        unless final_options[:verbose]
          context_mode = final_options[:shared_context] ? 'shared' : 'fresh'
          @output_manager.file_execution_start(file, testrun.total_tests, context_mode)
        end

        test_results = []
        success      = batch.run do
          last_result = batch.results.last
          test_results << last_result if last_result
        end

        file_failed_count                = test_results.count { |r| r[:status] == :failed }
        global_tally[:total_tests]      += batch.size
        global_tally[:total_failed]     += file_failed_count
        global_tally[:successful_files] += 1 if success

        duration = Time.now - file_start if defined?(file_start)
        @output_manager.file_success(file, batch.size, file_failed_count, duration)

        unless final_options[:verbose]
          @output_manager.batch_summary(batch.size, file_failed_count, duration)
          @output_manager.raw("")
        end

        return 1 unless success

      when :rspec
        @output_manager.info 'Executing with RSpec framework', 2
        translator.translate(testrun)
        require 'rspec/core'
        RSpec::Core::Runner.run([])
      when :minitest
        @output_manager.info 'Executing with Minitest framework', 2
        translator.translate(testrun)
        ARGV.clear
        require 'minitest/autorun'
      end

      0
    end

    def handle_timeout_error(file, ex)
      @output_manager.file_failure(file, "Timeout: #{ex.message}")
      1
    end

    def handle_syntax_error(file, ex)
      @output_manager.file_failure(file, "Syntax error: #{ex.message}")
      1
    end

    def handle_general_error(file, ex, final_options)
      @output_manager.error_phase
      @output_manager.info "File: #{Console.pretty_path(file)}", 1
      @output_manager.info "Error: #{Console.color(:red, ex.class.name)}", 1
      @output_manager.info "Message: #{ex.message}", 1

      if final_options[:verbose]
        @output_manager.trace "Backtrace:", 1
        ex.backtrace.first(5).each { |line| @output_manager.trace line, 2 }
      end

      backtrace_details = final_options[:verbose] ? ex.backtrace.first(3).join("\n") : nil
      @output_manager.file_failure(file, ex.message, backtrace_details)
      1
    end

    def show_grand_total(tally, _options)
      elapsed_time = Time.now - tally[:start_time]
      @output_manager.grand_total(
        tally[:total_tests],
        tally[:total_failed],
        tally[:successful_files],
        tally[:file_count],
        elapsed_time
      )
    end
  end
end
