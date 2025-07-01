# lib/tryouts/cli.rb

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
              batch = TestBatch.new(testrun, shared_context: final_options[:shared_context])

              context_mode = final_options[:shared_context] ? 'shared' : 'fresh'
              puts "Running #{file} with #{context_mode} context..."

              success = batch.run do |test_case|
                puts "  #{test_case.description}: #{batch.failed > 0 ? '❌' : '✅'}"
              end

              puts "Results: #{batch.size} tests, #{batch.failed} failed"
              return 1 unless success

            when :rspec
              translator.translate(testrun)
              require 'rspec/core'
              RSpec::Core::Runner.run([])
            when :minitest
              translator.translate(testrun)
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
      files   = []

      i = 0
      while i < args.length
        case args[i]
        when '--rspec'
          options[:framework] = :rspec
        when '--minitest'
          options[:framework] = :minitest
        when '--generate-rspec'
          options[:framework]     = :rspec
          options[:generate_only] = true
        when '--generate-minitest'
          options[:framework]     = :minitest
          options[:generate_only] = true
        when '--direct'
          options[:framework] = :direct
        when '--generate'
          options[:generate_only] = true
        when '--shared-context'
          options[:shared_context] = true
        when '--verbose', '-v'
          options[:verbose] = true
        when '--version', '-V'
          options[:version] = true
        when '--help', '-h'
          print_help
          exit 0
        else
          files << args[i]
        end
        i += 1
      end

      [files, options]
    end

    # opts.on('-q', '--quiet', 'Run in quiet mode') { Tryouts.quiet = true }
    # opts.on('-v', '--verbose', 'Run in verbose mode') { Tryouts.noisy = true }
    # opts.on('-f', '--fails', 'Show only failing tryouts') { Tryouts.fails = true }
    # opts.on('-D', '--debug', 'Run in debug mode') { Tryouts.debug = true }
    def self.print_help
      puts <<~HELP
        Usage: try [OPTIONS] FILE...

        Modern Tryouts test runner with framework translation

        Options:
          --direct              Direct execution with TestBatch (default)
          --rspec               Use RSpec framework
          --minitest            Use Minitest framework
          --shared-context      Override default context mode
          --generate-rspec      Generate RSpec code only
          --generate-minitest   Generate Minitest code only
          --generate            Generate code only (use with --rspec/--minitest)
          --verbose, -v         Verbose error output
          --help, -h            Show this help

        Framework Defaults:
          Direct:     Shared context (state persists across tests)
          RSpec:      Fresh context (each test isolated)
          Minitest:   Fresh context (each test isolated)

        Examples:
          try test_try.rb                          # Direct with shared context
          try --rspec test_try.rb                  # RSpec with fresh context
          try --direct --shared-context test_try.rb # Explicit shared context
          try --generate-rspec test_try.rb         # Output RSpec code only

        Framework Integration:
          Direct:   Native TestBatch execution with configurable context
          RSpec:    Generates describe/it blocks with proper setup/teardown
          Minitest: Generates test class with test_* methods

        File Format:
          ## Test description       # Test case marker
          code_to_test             # Ruby code
          #=> expected_result       # Expectation
      HELP
    end
  end
end
