# lib/tryouts/cli/opts.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    HELP = <<~HELP

      Framework Defaults:
        Tryouts:    Shared context (state persists across tests)
        RSpec:      Fresh context (each test isolated)
        Minitest:   Fresh context (each test isolated)

      Examples:
        try test_try.rb                             # Tryouts test runner with shared context
        try --rspec test_try.rb                     # RSpec with fresh context
        try --direct --shared-context test_try.rb   # Explicit shared context
        try --generate-rspec test_try.rb            # Output RSpec code only
        try --inspect test_try.rb                   # Inspect file structure and validation
        try --agent test_try.rb                     # Agent-optimized structured output
        try --agent --agent-limit 10000 tests/      # Agent mode with 10K token limit

      Agent Output Modes:
        --agent                                     # Structured, token-efficient output
        --agent-focus summary                       # Show counts and problem files only
        --agent-focus first-failure                 # Show first failure per file
        --agent-focus critical                      # Show errors/exceptions only
        --agent-limit 1000                          # Limit output to 1000 tokens
        --agent-tips                                # Include framework tips for LLMs
        --agent-command                             # Include copy-paste re-run command
        --agent-no-failures                         # Suppress failure details (summary only)

      File Naming & Organization:
        Files must end with '_try.rb' or '.try.rb' (e.g., auth_service_try.rb, user_model.try.rb)
        Auto-discovery searches: ./try/, ./tryouts/, ./*_try.rb, ./*.try.rb patterns
        Organize by feature/module: try/models/, try/services/, try/api/

      Testcase Structure (3 required parts)
        ## This is the description
        echo 'This is ruby code under test'
        true
        #=> true  # this is the expected result

      File Structure (3 sections):
        # Setup section (optional) - code before first testcase runs once before all tests
        @shared_var = "available to all test cases"

        ## TEST: Feature description
        # Test case body with plain Ruby code
        result = some_operation()
        #=> expected_value

        # Teardown section (optional) - code after last testcase runs once after all tests

      Execution Context:
        Shared Context (default): Instance variables persist across test cases
          - Use for: Integration testing, stateful scenarios, realistic workflows
          - Caution: Test order matters, state accumulates

        Fresh Context (--rspec/--minitest): Each test gets isolated environment
          - Use for: Unit testing, independent test cases
          - Setup variables copied to each test, but changes don't persist

      Writing Quality Tryouts:
        - Use realistic, plain Ruby code (avoid mocks, test harnesses)
        - Test descriptions start with ##, be specific about what's being tested
        - One result per test case (last expression is the result)
        - Use appropriate expectation types for clarity (#==> for boolean, #=:> for types)
        - Keep tests focused and readable - they serve as documentation

      Great Expectations System:
        #=>   Value equality        #==> Must be true         #=/=> Must be false
        #=|>  True OR false         #=!>  Must raise error    #=:>  Type matching
        #=~>  Regex matching        #=%>  Time constraints    #=*>  Non-nil result
        #=1>  STDOUT content        #=2>  STDERR content      #=<>  Intentional failure

      Exception Testing:
        ## Method 1: Rescue and test exception
        begin
          risky_operation
        rescue MySpecificError => e
          e.class
        end
        #=> MySpecificError

        ## Method 2: Let it raise and test with #=!> and #=~>
        risky_operation
        #=!> MySpecificError
        #=~> /Could not complete action/
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
          opts.on('-j', '--parallel [THREADS]', 'Run test files in parallel (optional thread count)') do |threads|
            options[:parallel] = true
            options[:parallel_threads] = threads.to_i if threads && threads.to_i > 0
          end

          opts.separator "\nParser Options:"
          opts.on('--strict', 'Require explicit test descriptions (fail on unnamed tests)') { options[:strict] = true }
          opts.on('--no-strict', 'Allow unnamed tests (legacy behavior)') { options[:strict] = false }
          opts.on('-w', '--warnings', 'Show parser warnings (default: true)') { options[:warnings] = true }
          opts.on('--no-warnings', 'Suppress parser warnings') { options[:warnings] = false }

          opts.separator "\nAgent-Optimized Output:"
          opts.on('-a', '--agent', 'Agent-optimized structured output for LLM context management') do
            options[:agent] = true
          end
          opts.on('--agent-limit TOKENS', Integer, 'Limit total output to token budget (default: 5000)') do |limit|
            options[:agent] = true
            options[:agent_limit] = limit
          end
          opts.on('--agent-focus TYPE', %w[failures first-failure summary critical],
                  'Focus mode: failures, first-failure, summary, critical (default: failures)') do |focus|
            options[:agent] = true
            options[:agent_focus] = focus.to_sym
          end
          opts.on('--agent-tips', 'Include tryouts framework tips and reminders in agent output') do
            options[:agent] = true
            options[:agent_tips] = true
          end
          opts.on('--agent-command', 'Include copy-paste command for re-running failures with -vfs') do
            options[:agent] = true
            options[:agent_command] = true
          end
          opts.on('--agent-no-failures', 'Suppress detailed failure list (show summary/command only)') do
            options[:agent] = true
            options[:agent_no_failures] = true
          end

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
