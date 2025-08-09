# lib/tryouts/file_processor.rb

require_relative 'prism_parser'
require_relative 'enhanced_parser'
require_relative 'test_executor'
require_relative 'cli/modes/inspect'
require_relative 'cli/modes/generate'

class Tryouts
  class FileProcessor
    # Supported parser types for validation and documentation
    PARSER_TYPES = [:enhanced, :prism].freeze
    def initialize(file:, options:, output_manager:, translator:, global_tally:)
      @file           = file
      @options        = options
      @output_manager = output_manager
      @translator     = translator
      @global_tally   = global_tally
    end

    def process
      testrun                     = create_parser(@file, @options).parse
      @global_tally[:file_count] += 1
      @output_manager.file_parsed(@file, testrun.total_tests)

      if @options[:inspect]
        handle_inspect_mode(testrun)
      elsif @options[:generate_only]
        handle_generate_only_mode(testrun)
      else
        execute_tests(testrun)
      end
    rescue TryoutSyntaxError => ex
      handle_syntax_error(ex)
    rescue StandardError, SystemStackError, LoadError, SecurityError, NoMemoryError => ex
      handle_general_error(ex)
    end

    private

    def create_parser(file, options)
      parser_type = options[:parser] || :prism  # default to legacy for safe rollout

      unless PARSER_TYPES.include?(parser_type)
        raise ArgumentError, "Unknown parser: #{parser_type}. Allowed types: #{PARSER_TYPES.join(', ')}"
      end

      case parser_type
      when :enhanced
        EnhancedParser.new(file)
      when :prism
        PrismParser.new(file)
      end
    end

    def handle_inspect_mode(testrun)
      mode = Tryouts::CLI::InspectMode.new(@file, testrun, @options, @output_manager, @translator)
      mode.handle
      0
    end

    def handle_generate_only_mode(testrun)
      mode = Tryouts::CLI::GenerateMode.new(@file, testrun, @options, @output_manager, @translator)
      mode.handle
      0
    end

    def execute_tests(testrun)
      tex = TestExecutor.new(@file, testrun, @options, @output_manager, @translator, @global_tally)
      tex.execute
    end

    def handle_syntax_error(ex)
      @output_manager.file_failure(@file, "Syntax error: #{ex.message}")
      1
    end

    def handle_general_error(ex)
      @global_tally[:total_errors] += 1 if @global_tally
      @output_manager.file_failure(@file, ex.message, ex.backtrace)
      1
    end
  end
end
