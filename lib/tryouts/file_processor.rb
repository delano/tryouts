# lib/tryouts/file_processor.rb
#
# frozen_string_literal: true

require_relative 'parsers/statement_parser'
require_relative 'test_executor'
require_relative 'cli/modes/inspect'
require_relative 'cli/modes/generate'

class Tryouts
  class FileProcessor
    def initialize(file:, options:, output_manager:, translator:, global_tally:)
      @file           = file
      @options        = options
      @output_manager = output_manager
      @translator     = translator
      @global_tally   = global_tally
    end

    # Returns the file's failure count. A file passes when that is zero,
    # also when it has no test cases or was only inspected, generated or
    # handed to RSpec or Minitest; one that fails to parse fails.
    def process
      aggregator = @global_tally[:aggregator]
      aggregator.increment_total_files
      failures   = process_file
      aggregator.increment_successful_files if failures.zero?
      failures
    end

    private

    def process_file
      testrun = StatementParser.new(@file, @options).parse

      # Report total test count (before filtering for display)
      # Line spec filtering affects output only, not execution
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
      message = "Syntax error: #{ex.message}"
      @global_tally[:aggregator].add_infrastructure_failure(:file_processing, @file, message, ex)
      @output_manager.file_failure(@file, message)
      1
    end

    def handle_general_error(ex)
      @global_tally[:aggregator].add_infrastructure_failure(:file_processing, @file, ex.message, ex)
      @output_manager.file_failure(@file, ex.message, ex.backtrace)
      1
    end
  end
end
