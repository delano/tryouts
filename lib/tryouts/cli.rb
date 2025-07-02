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
      Tryouts.debug 'CLI#initialize: Initializing CLI.'
      @options = {
        framework: :direct,     # Direct is now the default
        verbose: false,
        inspect: false,
      }
    end

    def run(files, **options)
      Tryouts.debug "CLI#run: Starting with files: #{files.inspect}, options: #{options.inspect}"
      @options.merge!(options)

      handle_version_flag(options)

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
        missing_files.each { |file| warn "Error: File not found: #{file}" }
        exit 1
      end
    end

    def process_files(files, final_options, global_tally, translator)
      overall_result = 0

      files.each do |file|
        result         = process_file(file, final_options, global_tally, translator)
        overall_result = result if result != 0 && overall_result == 0  # Track first failure
      end

      overall_result
    end

    def handle_version_flag(options)
      return unless options[:version]

      Tryouts.debug 'CLI#run: Version flag detected. Showing version and exiting.'
      puts "Tryouts version #{Tryouts::VERSION}"
      exit 0
    end

    def apply_framework_defaults(options)
      framework_defaults = FRAMEWORK_DEFAULTS[options[:framework]] || {}
      Tryouts.debug "CLI#run: Applying framework defaults: #{framework_defaults.inspect}"
      final_options      = framework_defaults.merge(options)
      Tryouts.debug "CLI#run: Final options: #{final_options.inspect}"
      final_options
    end

    def validate_framework(final_options)
      unless final_options[:framework] == :direct || FRAMEWORKS.key?(final_options[:framework])
        Tryouts.debug "CLI#run: Unknown framework detected: #{final_options[:framework]}"
        raise ArgumentError, "Unknown framework: #{final_options[:framework]}. Available: #{FRAMEWORKS.keys.join(', ')}, direct"
      end
    end

    def initialize_translator(final_options)
      translator = FRAMEWORKS[final_options[:framework]].new unless final_options[:framework] == :direct
      Tryouts.debug "CLI#run: Translator initialized for #{final_options[:framework]}." if translator
      translator
    end

    def initialize_global_tally
      global_tally = {
        total_tests: 0,
        total_failed: 0,
        file_count: 0,
        start_time: Time.now,
        successful_files: 0,
      }
      Tryouts.debug "CLI#run: Global tally initialized: #{global_tally.inspect}"
      global_tally
    end

    def process_file(file, final_options, global_tally, translator)
      Tryouts.debug "CLI#run: Processing file: #{file}"

      begin
        Tryouts.debug "CLI#run: Parsing file with PrismParser: #{file}"
        testrun                    = PrismParser.new(file).parse
        global_tally[:file_count] += 1
        Tryouts.debug "CLI#run: Parsed #{testrun.total_tests} test cases from #{file}. Current file count: #{global_tally[:file_count]}"

        if final_options[:inspect]
          handle_inspect_mode(file, testrun, final_options, translator)
        elsif final_options[:generate_only]
          handle_generate_only_mode(file, testrun, final_options, translator)
        else
          return execute_tests(file, testrun, final_options, global_tally, translator)
        end
      rescue TryoutSyntaxError => ex
        return handle_syntax_error(file, ex)
      rescue StandardError => ex
        return handle_general_error(file, ex, final_options)
      end

      0
    end

    def handle_inspect_mode(file, testrun, final_options, translator)
      Tryouts.debug 'CLI#run: Inspection mode activated.'
      puts "Inspecting: #{file}"
      puts '=' * 50
      puts "Found #{testrun.total_tests} test cases"
      puts "Setup code: #{testrun.setup.empty? ? 'None' : 'Present'}"
      puts "Teardown code: #{testrun.teardown.empty? ? 'None' : 'Present'}"
      puts

      testrun.test_cases.each_with_index do |tc, i|
        puts "Test #{i + 1}: #{tc.description}"
        puts "  Code lines: #{tc.code.lines.count}"
        puts "  Expectations: #{tc.expectations.size}"
        puts "  Range: #{tc.line_range}"
        puts
      end

      return unless final_options[:framework] != :direct

      Tryouts.debug "CLI#run: Testing framework translation for #{final_options[:framework]} in inspect mode."
      puts "Testing #{final_options[:framework]} translation..."
      framework_klass    = FRAMEWORKS[final_options[:framework]]
      inspect_translator = framework_klass.new

      translated_code = inspect_translator.generate_code(testrun)
      puts "#{final_options[:framework].to_s.capitalize} code generated (#{translated_code.lines.count} lines)"
      puts
    end

    def handle_generate_only_mode(file, testrun, final_options, translator)
      Tryouts.debug "CLI#run: Generate-only mode activated for #{final_options[:framework]}."
      puts "# Generated #{final_options[:framework]} code for #{file}"
      puts "# Updated: #{Time.now}"
      puts translator.generate_code(testrun)
      puts
    end

    def execute_tests(file, testrun, final_options, global_tally, translator)
      Tryouts.debug "CLI#run: Executing tests for #{file} with framework: #{final_options[:framework]}"
      case final_options[:framework]
      when :direct
        Tryouts.debug 'CLI#run: Direct execution mode.'
        batch = TestBatch.new(
          testrun,
          shared_context: final_options[:shared_context],
          verbose: final_options[:verbose],
          fails_only: final_options[:fails_only],
        )

        unless final_options[:verbose]
          context_mode = final_options[:shared_context] ? 'shared' : 'fresh'
          puts "Running #{file} with #{context_mode} context..."
        end

        test_results = []
        Tryouts.debug "CLI#run: Starting TestBatch run for #{file}."
        success      = batch.run do |test_case|
          last_result = batch.results.last
          test_results << last_result if last_result
          Tryouts.debug "CLI#run: TestBatch callback for #{test_case.description}, status: #{last_result[:status]}" if last_result
        end
        Tryouts.debug "CLI#run: TestBatch run finished for #{file}. Success: #{success}"

        file_failed_count                = test_results.count { |r| r[:status] == :failed }
        global_tally[:total_tests]      += batch.size
        global_tally[:total_failed]     += file_failed_count
        global_tally[:successful_files] += 1 if success
        Tryouts.debug "CLI#run: Updated global tally for #{file}. Total tests: #{global_tally[:total_tests]}, Total failed: #{global_tally[:total_failed]}"

        unless final_options[:verbose]
          puts "Results: #{batch.size} tests, #{file_failed_count} failed"
          puts
        end

        return 1 unless success

      when :rspec
        Tryouts.debug 'CLI#run: RSpec execution mode.'
        translator.translate(testrun)
        require 'rspec/core'
        RSpec::Core::Runner.run([])
        Tryouts.debug 'CLI#run: RSpec execution completed.'
      when :minitest
        Tryouts.debug 'CLI#run: Minitest execution mode.'
        translator.translate(testrun)
        ARGV.clear
        require 'minitest/autorun'
        Tryouts.debug 'CLI#run: Minitest execution completed.'
      end

      0
    end

    def handle_syntax_error(file, ex)
      Tryouts.debug "CLI#run: Syntax error in #{file}: #{ex.message}"
      warn "Syntax error in #{file}: #{ex.message}"
      1
    end

    def handle_general_error(file, ex, final_options)
      Tryouts.debug "CLI#run: General error processing #{file}: #{ex.message}"
      warn "Error processing #{file}: #{ex.message}"
      warn ex.backtrace.join("\n") if final_options[:verbose]
      1
    end

    def show_grand_total(tally, _options)
      Tryouts.debug "CLI#show_grand_total: Calculating and displaying grand total. Tally: #{tally.inspect}"
      elapsed_time = Time.now - tally[:start_time]
      passed_count = tally[:total_tests] - tally[:total_failed]

      puts '=' * 60
      puts 'Grand Total:'

      if tally[:total_failed] > 0
        puts "#{tally[:total_failed]} failed, #{passed_count} passed (#{format('%.2f', elapsed_time)}s)"
      else
        puts "#{tally[:total_tests]} tests passed (#{format('%.2f', elapsed_time)}s)"
      end

      puts "Results: #{tally[:total_tests]} tests, #{tally[:total_failed]} failed"
      puts "Files processed: #{tally[:successful_files]}/#{tally[:file_count]} successful"
      Tryouts.debug 'CLI#show_grand_total: Grand total displayed.'
    end
  end
end
