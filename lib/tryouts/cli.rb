# lib/tryouts/cli.rb

require 'optparse'

require_relative 'cli/opts'
require_relative 'cli/formatters'
require_relative 'test_runner'

class Tryouts
  class CLI
    def initialize
      @options = {
        framework: :direct,
        verbose: false,
        inspect: false,
      }
    end

    def run(files, **options)
      @options.merge!(options)

      output_manager = FormatterFactory.create_output_manager(@options)

      handle_version_flag(@options, output_manager)
      validate_files_exist(files, output_manager)

      runner = TestRunner.new(
        files: files,
        options: @options,
        output_manager: output_manager,
      )

      runner.run
    end

    private

    def handle_version_flag(options, output_manager)
      return unless options[:version]

      output_manager.raw("Tryouts version #{Tryouts::VERSION}")
      exit 0
    end

    def validate_files_exist(files, output_manager)
      missing_files = files.reject { |file| File.exist?(file) }

      unless missing_files.empty?
        missing_files.each { |file| output_manager.error("File not found: #{file}") }
        exit 1
      end
    end
  end
end
