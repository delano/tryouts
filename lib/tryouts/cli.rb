# lib/tryouts/cli.rb

require 'optparse'
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
      }
    end

    def run(files, **options)
      @options.merge!(options)

      if options[:version]
        puts "Tryouts version #{Tryouts::VERSION}"
        exit 0
      end

      # Apply framework-specific defaults
      framework_defaults = FRAMEWORK_DEFAULTS[@options[:framework]] || {}
      final_options      = framework_defaults.merge(@options)

      # Direct execution doesn't use translators
      unless final_options[:framework] == :direct || FRAMEWORKS.key?(final_options[:framework])
        raise ArgumentError, "Unknown framework: #{final_options[:framework]}. Available: #{FRAMEWORKS.keys.join(', ')}, direct"
      end

      translator = FRAMEWORKS[final_options[:framework]].new unless final_options[:framework] == :direct

      files.each do |file|
        unless File.exist?(file)
          warn "Error: File not found: #{file}"
          next
        end

        begin
          testrun = PrismParser.new(file).parse

          if final_options[:generate_only]
            puts "# Generated #{final_options[:framework]} code for #{file}"
            puts "# Updated: #{Time.now}"
            puts translator.generate_code(testrun)
            puts
          else
            # Execute the translation and run tests
            case final_options[:framework]
            when :direct
              # Direct execution with TestBatch
              batch = TestBatch.new(
                testrun,
                shared_context: final_options[:shared_context],
                verbose: final_options[:verbose],
                fails_only: final_options[:fails_only]
              )

              unless final_options[:verbose]
                context_mode = final_options[:shared_context] ? 'shared' : 'fresh'
                puts "Running #{file} with #{context_mode} context..."
              end

              success = batch.run do |test_case|
                unless final_options[:verbose]
                  puts "  #{test_case.description}: #{batch.failed > 0 ? '❌' : '✅'}"
                end
              end

              unless final_options[:verbose]
                puts "Results: #{batch.size} tests, #{batch.failed} failed"
              end

              return 1 unless success

            when :rspec
              translator.translate(testrun)
              require 'rspec/core'
              RSpec::Core::Runner.run([])
            when :minitest
              translator.translate(testrun)
              # Clear ARGV to prevent Minitest from processing our arguments
              original_argv = ARGV.dup
              ARGV.clear
              require 'minitest/autorun'
              # Minitest will automatically discover and run the generated test class
            end
          end
        rescue TryoutSyntaxError => ex
          warn "Syntax error in #{file}: #{ex.message}"
          return 1
        rescue StandardError => ex
          warn "Error processing #{file}: #{ex.message}"
          warn ex.backtrace.join("\n") if final_options[:verbose]
          return 1
        end
      end

      0 # success
    end

    def self.parse_args(args)
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: try [OPTIONS] FILE...\n\nModern Tryouts test runner with framework translation"

        opts.separator "\nFramework Options:"
        opts.on('--direct', 'Direct execution with TestBatch (default)') { options[:framework] = :direct }
        opts.on('--rspec', 'Use RSpec framework') { options[:framework] = :rspec }
        opts.on('--minitest', 'Use Minitest framework') { options[:framework] = :minitest }

        opts.separator "\nGeneration Options:"
        opts.on('--generate-rspec', 'Generate RSpec code only') do
          options[:framework] = :rspec
          options[:generate_only] = true
        end
        opts.on('--generate-minitest', 'Generate Minitest code only') do
          options[:framework] = :minitest
          options[:generate_only] = true
        end
        opts.on('--generate', 'Generate code only (use with --rspec/--minitest)') { options[:generate_only] = true }

        opts.separator "\nExecution Options:"
        opts.on('--shared-context', 'Override default context mode') { options[:shared_context] = true }
        opts.on('--no-shared-context', 'Override default context mode') { options[:shared_context] = false }
        opts.on('-v', '--verbose', 'Show detailed test output with line numbers') { options[:verbose] = true }
        opts.on('-f', '--fails', 'Show only failing tests (with --verbose)') { options[:fails_only] = true }

        opts.separator "\nGeneral Options:"
        opts.on('-V', '--version', 'Show version') { options[:version] = true }
        opts.on('-D', '--debug', 'Enable debug mode') { Tryouts.debug = true }
        opts.on('-h', '--help', 'Show this help') do
          puts opts
          exit 0
        end

        opts.separator <<~HELP

        Framework Defaults:
          Tryouts:    Shared context (state persists across tests)
          RSpec:      Fresh context (each test isolated)
          Minitest:   Fresh context (each test isolated)

        Examples:
          try test_try.rb                          # Tryouts test runner with shared context
          try --rspec test_try.rb                  # RSpec with fresh context
          try --direct --shared-context test_try.rb # Explicit shared context
          try --generate-rspec test_try.rb         # Output RSpec code only

        File Format:
          ## Test description       # Test case marker
          code_to_test             # Ruby code
          #=> expected_result       # Expectation
        HELP
      end

      files = parser.parse(args)
      [files, options]
    rescue OptionParser::InvalidOption => e
      warn "Error: #{e.message}"
      warn "Try 'try --help' for more information."
      exit 1
    end

  end
end
