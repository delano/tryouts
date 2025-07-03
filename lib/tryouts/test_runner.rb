# lib/tryouts/test_runner.rb

require_relative 'prism_parser'
require_relative 'testbatch'
require_relative 'translators/rspec_translator'
require_relative 'translators/minitest_translator'
require_relative 'file_processor'

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
      @files          = files
      @options        = apply_framework_defaults(options)
      @output_manager = output_manager
      @translator     = initialize_translator
      @global_tally   = initialize_global_tally
    end

    def run
      log_run_info
      validate_framework

      result = process_files
      show_grand_total if @global_tally[:file_count] > 1
      result
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
        total_tests: 0,
        total_failed: 0,
        file_count: 0,
        start_time: Time.now,
        successful_files: 0,
      }
    end

    def process_files
      failure_count = 0

      @files.each do |file|
        result         = process_file(file)
        failure_count += result unless result.zero?
        status         = result.zero? ? Console.color(:green, 'PASS') : Console.color(:red, 'FAIL')
        @output_manager.info "#{status} #{Console.pretty_path(file)} (#{result} failures)", 1
      end

      failure_count
    end

    def process_file(file)
      FileProcessor.new(
        file: file,
        options: @options,
        output_manager: @output_manager,
        translator: @translator,
        global_tally: @global_tally,
      ).process
    end

    def show_grand_total
      elapsed_time = Time.now - @global_tally[:start_time]
      @output_manager.grand_total(
        @global_tally[:total_tests],
        @global_tally[:total_failed],
        @global_tally[:successful_files],
        @global_tally[:file_count],
        elapsed_time,
      )
    end
  end
end
