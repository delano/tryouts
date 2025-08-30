# lib/tryouts/file_processor.rb

require_relative 'parsers/prism_parser'
require_relative 'parsers/enhanced_parser'
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

      # Apply line spec filtering before reporting test counts
      if @options[:line_spec]
        testrun = filter_testrun_by_line_spec(testrun)
      end

      @global_tally[:aggregator].increment_total_files
      @output_manager.file_parsed(@file, testrun.total_tests)
      @output_manager.parser_warnings(@file, warnings: testrun.warnings)

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

    def filter_testrun_by_line_spec(testrun)
      require_relative 'cli/line_spec_parser'

      line_spec = @options[:line_spec]

      # Filter test cases to only those that match the line spec
      filtered_cases = testrun.test_cases.select do |test_case|
        Tryouts::CLI::LineSpecParser.matches?(test_case, line_spec)
      end

      # Check if any tests matched the line specification
      if filtered_cases.empty?
        @output_manager.file_failure(@file, "No test cases found matching line specification: #{line_spec}")
        return testrun  # Return original testrun to avoid breaking the pipeline
      end

      # Create a new testrun with filtered cases
      # We need to preserve the setup and teardown but only include matching tests
      testrun.class.new(
        setup: testrun.setup,
        test_cases: filtered_cases,
        teardown: testrun.teardown,
        source_file: testrun.source_file,
        metadata: testrun.metadata,
        warnings: testrun.warnings
      )
    end

    def create_parser(file, options)
      parser_type = options[:parser] || :enhanced  # enhanced parser is now the default

      unless PARSER_TYPES.include?(parser_type)
        raise ArgumentError, "Unknown parser: #{parser_type}. Allowed types: #{PARSER_TYPES.join(', ')}"
      end

      case parser_type
      when :enhanced
        EnhancedParser.new(file, options)
      when :prism
        PrismParser.new(file, options)
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
      if @global_tally
        @global_tally[:aggregator].add_infrastructure_failure(
          :file_processing, @file, ex.message, ex
        )
      end
      @output_manager.file_failure(@file, ex.message, ex.backtrace)
      1
    end
  end
end
