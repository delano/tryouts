# frozen_string_literal: true

require_relative 'prism_parser'
require_relative 'translators/rspec_translator'
require_relative 'translators/minitest_translator'

class Tryouts
  class CLI
    FRAMEWORKS = {
      rspec: Translators::RSpecTranslator,
      minitest: Translators::MinitestTranslator
    }.freeze

    def initialize
      @options = {
        framework: :rspec,
        generate_only: false,
        verbose: false
      }
    end

    def run(files, **options)
      @options.merge!(options)

      unless FRAMEWORKS.key?(@options[:framework])
        raise ArgumentError, "Unknown framework: #{@options[:framework]}. Available: #{FRAMEWORKS.keys.join(', ')}"
      end

      translator = FRAMEWORKS[@options[:framework]].new

      files.each do |file|
        unless File.exist?(file)
          $stderr.puts "Error: File not found: #{file}"
          next
        end

        begin
          testrun = PrismParser.new(file).parse

          if @options[:generate_only]
            puts "# Generated #{@options[:framework]} code for #{file}"
            puts translator.generate_code(testrun)
            puts
          else
            # Execute the translation and run tests
            case @options[:framework]
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

        rescue TryoutSyntaxError => e
          $stderr.puts "Syntax error in #{file}: #{e.message}"
          return 1
        rescue StandardError => e
          $stderr.puts "Error processing #{file}: #{e.message}"
          $stderr.puts e.backtrace.join("\n") if @options[:verbose]
          return 1
        end
      end

      0 # success
    end

    def self.parse_args(args)
      options = {}
      files = []

      i = 0
      while i < args.length
        case args[i]
        when '--rspec'
          options[:framework] = :rspec
        when '--minitest'
          options[:framework] = :minitest
        when '--generate-rspec'
          options[:framework] = :rspec
          options[:generate_only] = true
        when '--generate-minitest'
          options[:framework] = :minitest
          options[:generate_only] = true
        when '--generate'
          options[:generate_only] = true
        when '--verbose', '-v'
          options[:verbose] = true
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
          --rspec               Use RSpec framework (default)
          --minitest            Use Minitest framework
          --generate-rspec      Generate RSpec code only
          --generate-minitest   Generate Minitest code only
          --generate            Generate code only (use with --rspec/--minitest)
          --verbose, -v         Verbose error output
          --help, -h            Show this help

        Examples:
          try test_try.rb                    # Run with RSpec (default)
          try --minitest test_try.rb         # Run with Minitest
          try --generate-rspec test_try.rb   # Output RSpec code only
          try *.try.rb                       # Run all tryout files

        Framework Integration:
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
