# lib/tryouts/cli/opts.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    HELP = <<~HELP

      Framework Defaults:
        Tryouts:    Shared context (the file runs as one script)
        RSpec:      Fresh context (each test isolated)
        Minitest:   Fresh context (each test isolated)

      Examples:
        try test_try.rb                             # Tryouts test runner with shared context
        try --no-shared-context test_try.rb         # Tryouts test runner, fresh context per test
        try --rspec test_try.rb                     # RSpec with fresh context
        try -j 4 try/                               # Files in parallel on 4 threads (or --parallel=4)
        try -jvf try/                               # Flags after -j stay flags: -j -vf (-j4v is -j4 -v)
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

      Testcase Structure (3 required parts):
        ## Description of what the test shows
        greeting = "Hello, " + "world"
        greeting.length
        #=> 12    # expectation about the value of the statement above it

      File Structure:
        A tryouts file is a Ruby script, run top to bottom. A test case is the
        code from a ## description down to the statement its expectations sit
        under. Code before the first test is setup, code after the last test is
        teardown, and code between two tests runs in order where it stands.

        require 'json'
        @settings = { "retries" => 3 }
        retries = @settings["retries"]

        ## Retries come from the settings
        retries + 1
        #=> 4

        ## An expectation can also trail the statement it checks
        JSON.generate(@settings) #=> '{"retries":3}'

        @settings["retries"] = 5

        ## Code between tests has already run
        ## when the next test starts
        @settings["retries"]
        #=> 5

        Rules:
          - ## starts a description; ## lines on adjacent lines join into one,
            also across a bare ## spacer line, and a blank line or plain #
            line ends the block
          - A single # line is an ordinary comment, never a description
          - An expectation checks the statement directly above it, or the
            statement it trails on the same line (1 + 1 #=> 2)
          - "# =>" with a space means the same as "#=>"
          - One statement can have several expectations; all must pass
          - Every test needs a ## description (--no-strict allows unnamed tests)
          - An expectation directly under a ## line, with no code between them,
            does not apply to the test above: it warns and fails as a test of
            its own. A bare ## line is a plain comment
          - A failure in setup, or in code between tests, stops the file; the
            tests left are reported as not run
          - The file runs at the top level like a script: class Foo is ::Foo,
            top-level include mixes into Object, top-level using raises (use it
            in a class/module body)
          - A top-level def is a method on the file's own main object, not on
            Object: top-level code and blocks can call it, a class the file
            defines cannot
          - Classes and constants the file defines are global and stay defined
            for the rest of the run, so later files see them (files run
            together with -j share them too); give classes distinct names
          - Leading magic comments (# frozen_string_literal: true) apply to
            every section and expectation, also under --rspec and --minitest
          - BEGIN { } runs with the section it is in, not before the file, and
            DATA is not defined (the text after __END__ is ignored)
          - Each test has a 30-second deadline; a Timeout::Error raised by the
            test code is reported as itself

      Execution Context:
        Shared Context (default): the whole file runs in one binding
          - Local and instance variables persist from each statement to the next,
            across setup, tests, code between tests, and teardown
          - Setup and teardown run once
          - Use for: Integration testing, stateful scenarios, realistic workflows
          - Caution: Test order matters, state accumulates

        Fresh Context (--no-shared-context): each test gets a new object and binding
          - Before each test, setup runs again in the new binding, followed by
            any code between earlier tests; then the test and its expectations;
            then teardown, in the same binding
          - No local or instance variable crosses between tests
          - Before setup runs again for the 2nd and later tests, the file's
            top-level classes and constants are removed, so class definitions
            run again (inherited hooks see each run); constants nested in an
            existing namespace stay, and nothing is removed after the last test
          - Globals and reopened existing classes are not reset
          - Setup and teardown output and failures are reported once
          - Use for: Unit testing, independent test cases

        --rspec and --minitest translate the file into that framework and use its
        own setup and teardown hooks (RSpec: once around all examples; Minitest:
        around every test). Setup instance variables reach the tests, setup
        locals do not. Every expectation is judged as in direct mode, and
        --rspec exits non-zero when an example fails. --generate-* code
        translates most operators and writes a failing assertion, naming the
        expectation, for #=<>, #=%>, #=1>, #=2> and mistyped ones.

      Writing Quality Tryouts:
        - Use realistic, plain Ruby code (avoid mocks, test harnesses)
        - Test descriptions start with ##, be specific about what's being tested
        - The last statement of a test case is the one its expectations check
        - Use appropriate expectation types for clarity (#==> for boolean, #=:> for types)
        - Keep tests focused and readable - they serve as documentation

      Great Expectations System:
        #=>   expr               result == expr
        #==>  expr               expr is exactly true
        #=/=> expr               expr is exactly false
        #=|>  expr               expr is true or false
        #=!>  ErrorClass | expr  test raised: error.is_a?(ErrorClass), or expr is truthy
        #=:>  Class              result.is_a?(Class)
        #=~>  /regex/            result.to_s matches (the message, if the test raised)
        #=%>  ms                 test code ran within ms milliseconds (+10% tolerance)
        #=*>                     result is not nil
        #=<>  /regex/ | expr     negation: must not match a regex; a true/false
                                 expr must be false; otherwise result != expr
        #=1>  "text" | /regex/   stdout includes the text or matches the regex
        #=2>  "text" | /regex/   stderr includes the text or matches the regex
        A mistyped operator (e.g. #=x>, #=>>) always fails, and so does ##=>
        (write #=> to assert, or # #=> to comment an expectation out). So does
        one missing its = (#~> /x/, #:> String, #>= 5); a spaced comparison
        (# >= 2.0) and dividers (# =====>, #------>) are comments.
        One missing its > (#== 5, #=~ /x/) is a plain comment: a ## test whose
        code holds one and has no expectation gets a warning that its code
        runs as setup, an interlude or teardown.

        Every expectation is Ruby evaluated in the test's binding. It can use
        the test's local and instance variables, and:
          result, _     value of the statement under test (the exception, if it raised)
          error         the exception the test raised, or nil
          elapsed_ms    how long the test code took, in milliseconds

      Exception Testing:
        ## Method 1: Rescue and test the exception as a value
        begin
          Integer("forty-two")
        rescue ArgumentError => e
          e.class
        end
        #=> ArgumentError

        ## Method 2: Let it raise and declare it with #=!>
        Integer("forty-two")
        #=!> ArgumentError
        #=~> /invalid value/
        #==> error.message.include?("forty-two")

        The test code runs once. #=!> fails if nothing was raised. A test
        without #=!> that raises is reported as an error, unless it has a
        #=:> or #=~> expectation to check the raised error's class or message.
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
          # The thread count is an optional Integer, so a file path after the
          # option is never taken for it. -j takes it as the next word or
          # attached (-j 4, -j4); --parallel only after = (--parallel=4),
          # because OptionParser rejects, rather than leaves, a non-Integer
          # word after a long option.
          { '-j [THREADS]' => 'Run test files in parallel (optional thread count)',
            '--parallel[=THREADS]' => 'Same as -j (--parallel=4)' }.each do |switch, description|
            opts.on(switch, Integer, description) do |threads|
              options[:parallel]         = true
              options[:parallel_threads] = threads if threads&.positive?
            end
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

        files = parser.parse(split_parallel_clusters(args))
        Tryouts.trace "Parsed files: #{files.inspect}, options: #{options.inspect}"
        [files, options]
      rescue OptionParser::ParseError => ex
        warn "Error: #{ex.message}"
        warn "Try 'try --help' for more information."
        exit 1
      end

      private

      # OptionParser reads everything bundled after -j as its optional thread
      # count and silently drops what is not a number, so -jv would lose -v.
      # The count is only the digits attached to -j; the letters after them
      # are flags of their own: -jv is -j -v, and -j4v is -j4 -v.
      def split_parallel_clusters(args)
        options_end = args.index('--') || args.size
        args.take(options_end).flat_map do |arg|
          match = arg.match(/\A(-[a-zA-Z]*?j\d*)([a-zA-Z].*)\z/)
          match ? [match[1], "-#{match[2]}"] : arg
        end + args.drop(options_end)
      end
    end
  end
end
