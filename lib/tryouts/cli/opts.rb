# lib/tryouts/cli/opts.rb

class Tryouts
  class CLI
    HELP = <<~HELP

      Framework Defaults:
        Tryouts:    Shared context (state persists across tests)
        RSpec:      Fresh context (each test isolated)
        Minitest:   Fresh context (each test isolated)

      Examples:
        try test_try.rb                          # Tryouts test runner with shared context
        try --rspec test_try.rb                  # RSpec with fresh context
        try --direct --shared-context test_try.rb # Explicit shared context
        try --generate-rspec test_try.rb         # Output RSpec code only
        try --inspect test_try.rb                # Inspect file structure and validation

      File Format:
        ## Test description       # Test case marker
        code_to_test              # Ruby code
        #=> expected_result       # Expectation (various types available)

      Great Expectations System:
        Multiple expectation types are supported for different testing needs.

        #=>   Value equality        #==> Must be true         #=/=> Must be false
        #=|>  True OR false         #=!>  Must raise error    #=:>  Type matching
        #=~>  Regex matching        #=%>  Time constraints    #=1>  STDOUT content
        #=2>  STDERR content        #=<>  Intentional failure
    HELP

    class << self
      def parse_args(args)
        Tryouts.trace "Parsing arguments: #{args.inspect}"
        options = {}

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: try [OPTIONS] FILE...\n\nModern Tryouts test runner with framework translation"

          opts.separator "\nFramework Options:"
          opts.on('--direct', 'Direct execution with TestBatch (default)') { options[:framework] = :direct }
          opts.on('--rspec', 'Use RSpec framework') { options[:framework]                        = :rspec }
          opts.on('--minitest', 'Use Minitest framework') { options[:framework]                  = :minitest }

          opts.separator "\nGeneration Options:"
          opts.on('--generate-rspec', 'Generate RSpec code only') do
            options[:framework]     = :rspec
            options[:generate_only] = true
          end
          opts.on('--generate-minitest', 'Generate Minitest code only') do
            options[:framework]     = :minitest
            options[:generate_only] = true
          end
          opts.on('--generate', 'Generate code only (use with --rspec/--minitest)') do
            options[:generate_only] = true
            options[:framework]   ||= :rspec
          end

          opts.separator "\nExecution Options:"
          opts.on('--shared-context', 'Override default context mode') { options[:shared_context]         = true }
          opts.on('--no-shared-context', 'Override default context mode') { options[:shared_context]      = false }
          opts.on('-v', '--verbose', 'Show detailed test output with line numbers') { options[:verbose]   = true }
          opts.on('-f', '--fails', 'Show only failing tests') { options[:fails_only]                      = true }
          opts.on('-q', '--quiet', 'Minimal output (dots and summary only)') { options[:quiet]            = true }
          opts.on('-c', '--compact', 'Compact single-line output') { options[:compact]                    = true }
          opts.on('-l', '--live', 'Live status display') { options[:live_status]                          = true }

          opts.separator "\nParser Options:"
          opts.on('--enhanced-parser', 'Use enhanced parser with inhouse comment extraction (default)') { options[:parser] = :enhanced }
          opts.on('--legacy-parser', 'Use legacy prism parser') { options[:parser] = :prism }

          opts.separator "\nInspection Options:"
          opts.on('-i', '--inspect', 'Inspect file structure without running tests') { options[:inspect] = true }

          opts.separator "\nGeneral Options:"
          opts.on('-s', '--stack-traces', 'Show stack traces for exceptions') do
            options[:stack_traces] = true
            Tryouts.stack_traces = true
          end
          opts.on('-V', '--version', 'Show version') { options[:version] = true }
          opts.on('-D', '--debug', 'Enable debug mode') do
            options[:debug] = true
            options[:stack_traces] = true  # Debug mode auto-enables stack traces
            Tryouts.debug   = true
            Tryouts.stack_traces = true
          end
          opts.on('-h', '--help', 'Show this help') do
            puts opts
            exit 0
          end

          opts.separator HELP.freeze
        end

        files = parser.parse(args)
        Tryouts.trace "Parsed files: #{files.inspect}, options: #{options.inspect}"
        [files, options]
      rescue OptionParser::InvalidOption => ex
        warn "Error: #{ex.message}"
        warn "Try 'try --help' for more information."
        exit 1
      end
    end
  end
end
