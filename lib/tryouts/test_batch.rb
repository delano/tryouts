# lib/tryouts/test_batch.rb
#
# frozen_string_literal: true

require 'monitor'
require 'stringio'
require_relative 'script_binding'
require_relative 'expectation_evaluators/registry'
require_relative 'cli/line_spec_parser'

class Tryouts
  # Executes one parsed file.
  #
  # Shared context (the default) runs the file as the script it looks like:
  # setup, each test, each interlude and teardown are evaluated in source
  # order against one Binding, so local and instance variables persist from
  # each statement to the next.
  #
  # Fresh context gives every test its own object and Binding, the way
  # setup/teardown hooks work in RSpec or Minitest. For each test it evaluates
  # the setup, then every interlude above the test (so the test sees the same
  # state it would see in the script, minus the other tests), then the test
  # and its expectations, then the teardown. Nothing a test does is visible to
  # any other test.
  class TestBatch
    # $stdout/$stderr are process-global, not Fiber- or thread-local. Under
    # --parallel (Concurrent::ThreadPoolExecutor), concurrent redirects would
    # clobber each other and could leave $stdout pointing at a dead StringIO
    # process-wide. Every redirect (capture_output and capture_streams)
    # synchronizes on this lock so the redirect/execute/restore window is
    # serialized across threads.
    #
    # A Monitor (reentrant) is required because capture_streams runs nested
    # inside capture_output; a plain Mutex would self-deadlock.
    OUTPUT_CAPTURE_MONITOR = Monitor.new

    # Exceptions a test that declares #=!> can catch. Interrupts and exit are
    # deliberately absent.
    EXPECTABLE_ERRORS = [StandardError, ScriptError, SystemStackError, NoMemoryError, SecurityError].freeze

    # Raised when a test outlives the framework's own deadline. A class of its
    # own, so a Timeout::Error raised by the code under test (Net::ReadTimeout,
    # a Timeout.timeout of its own) is an ordinary error. Not a StandardError:
    # test code's `rescue => e` and a #=!> StandardError must not catch it.
    class DeadlineExceeded < Exception; end # rubocop:disable Lint/InheritException
    private_constant :DeadlineExceeded

    attr_reader :testrun, :failed_count, :status, :results, :output_manager

    def initialize(testrun, **options)
      @testrun         = testrun
      @options         = options
      @shared          = options[:shared_context] == true
      @output_manager  = options[:output_manager]
      @global_tally    = options[:global_tally]
      @line_spec       = options[:line_spec] # filters output only
      @test_timeout    = options[:test_timeout] || 30
      @failed_count    = 0
      @status          = :pending
      @results         = []
      @start_time      = nil
      @test_case_count = 0
      @aborted         = false
      @ran             = {} # sections that have run; their announcement and output are shown once
      @failed_sections = {} # sections whose failure was reported; a repeat is not reported again
      @teardown_report = [] # fresh context: what the teardown shows, held until after the last test

      # One Binding for the whole file in shared mode
      @binding = @shared ? ScriptBinding.create : nil

      # Circuit breaker for batch-level failure protection
      @consecutive_failures     = 0
      @max_consecutive_failures = options[:max_consecutive_failures] || 10
      @circuit_breaker_active   = false
    end

    # Constants the file defined on Object are removed when it finishes, so
    # another file may define the same names (see ScriptBinding).
    def run(before_test_hook = nil, &)
      return false if empty?

      @start_time      = Time.now
      @test_case_count = @testrun.total_tests

      @output_manager&.execution_phase(@test_case_count)
      @output_manager&.info("Context: #{context_name}", 1)
      @output_manager&.file_start(path, context: context_name.to_sym)

      if @shared
        @output_manager&.info('Running global setup...', 2)
        run_section(:setup, @testrun.setup, @binding)
        return abort_batch if @aborted
      end

      run_test_cases(before_test_hook, &)
      announce_fresh_teardown if @aborted && !@shared
      return abort_batch if @aborted

      # e.g. the quiet formatter prints a newline after all test dots
      @output_manager&.file_end(path, context: context_name.to_sym)

      @shared ? run_section(:teardown, @testrun.teardown, @binding) : announce_fresh_teardown
      finalize_results

      @status = :completed
      !failed?
    ensure
      ScriptBinding.remove_constants(path)
    end

    def empty?
      @testrun.empty?
    end

    def size
      @testrun.total_tests
    end

    def test_cases
      @testrun.test_cases
    end

    def path
      @testrun.source_file
    end

    def failed?
      @failed_count > 0
    end

    def completed?
      @status == :completed
    end

    private

    def context_name
      @shared ? 'shared' : 'fresh'
    end

    def run_test_cases(before_test_hook, &)
      interludes = []
      idx        = 0

      test_cases.each do |test_case|
        if test_case.is_a?(OrphanBlock)
          if @shared
            run_section(:orphan, test_case, @binding)
            break if @aborted
          else
            interludes << test_case
          end
          next
        end

        idx += 1
        @output_manager&.trace("Test #{idx}/#{@test_case_count}: #{test_case.description}", 2)

        if @circuit_breaker_active
          @output_manager&.error("Circuit breaker active - skipping remaining tests after #{@consecutive_failures} consecutive failures")
          break
        end

        run_single_test(test_case, idx, interludes, before_test_hook, &)
        break if @aborted
      end
    end

    # Display filtering (line_spec) applies to test_start/test_end and result
    # output only. Every test is executed.
    #
    # In fresh context the setup and interludes run before the test starts,
    # so the setup is announced ahead of the first test (as in shared
    # context) and a setup failure never leaves a test half-reported. The
    # teardown runs after the test's result.
    def run_single_test(test_case, idx, interludes, before_test_hook)
      binding = @shared ? @binding : fresh_binding(interludes, test_case)
      return nil if @aborted

      display = should_display_test_result?(test_case)
      @output_manager&.test_start(test_case, idx, @test_case_count) if display

      before_test_hook&.call(test_case)

      output = +''
      result = capture_output(output) { execute_test_case(test_case, binding) }
      result = result.with(captured_output: output) unless output.empty?

      process_test_result(result, display)
      @output_manager&.test_end(test_case, idx, @test_case_count) if display

      finish_fresh_test(binding) unless @shared
      update_circuit_breaker(result)
      yield(test_case) if block_given?
      result
    end

    # The test's teardown, then its constants go, so the setup defines fresh
    # ones for the next test (`class Point < Struct.new(:x, :y)` would
    # otherwise be a superclass mismatch on the second run).
    def finish_fresh_test(binding)
      run_section(:teardown, @testrun.teardown, binding)
    ensure
      ScriptBinding.remove_constants(path)
    end

    # A new object and Binding with the setup and the preceding interludes
    # already evaluated in it, for test_case.
    def fresh_binding(interludes, test_case)
      binding = ScriptBinding.create
      run_section(:setup, @testrun.setup, binding, test_case)
      interludes.each do |interlude|
        break if @aborted

        run_section(:orphan, interlude, binding, test_case)
      end
      binding
    end

    # Run the test code once, then evaluate every expectation against what it
    # produced. The timeout covers both.
    def execute_test_case(test_case, binding)
      context = execute_with_timeout(test_case) do
        ctx = run_test_code(test_case, binding)
        [ctx, evaluate_expectations(test_case, ctx)]
      end
      build_test_result(test_case, *context)
    rescue SystemExit, SignalException => ex
      Tryouts.debug "Test received #{ex.class}: #{ex.message}"
      build_error_result(test_case, StandardError.new("Test terminated by #{ex.class}: #{ex.message}"))
    rescue *EXPECTABLE_ERRORS => ex
      build_error_result(test_case, ex)
    end

    # @return [ExpectationEvaluators::EvaluationContext]
    def run_test_code(test_case, binding)
      value  = nil
      error  = nil
      stdout = test_case.expectations.any?(&:output?) ? StringIO.new : nil
      stderr = stdout && StringIO.new

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
      begin
        value = stdout ? capture_streams(stdout, stderr) { eval_section(test_case, binding) } : eval_section(test_case, binding)
      rescue *EXPECTABLE_ERRORS => ex
        raise unless expects_error?(test_case, ex)

        error = ex
      end
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) - started

      ExpectationEvaluators::EvaluationContext.new(
        binding: binding,
        path: test_case.path,
        magic_comments: @testrun.magic_comments,
        result: error || value,
        error: error,
        elapsed_ns: elapsed,
        stdout: stdout&.string,
        stderr: stderr&.string,
      )
    end

    # A test that declares #=!> expects to raise. One that checks a raised
    # error's type (#=:>) or message (#=~>) may catch an ordinary error too.
    # Anything else that raises is a test error.
    def expects_error?(test_case, error)
      return true if test_case.exception_expectations?

      error.is_a?(StandardError) && test_case.expectations.any? { |exp| exp.result_type? || exp.regex_match? }
    end

    # The file's magic comments go on the lines above the code, so the code
    # keeps its own line numbers.
    def eval_section(section, binding)
      magic = @testrun.magic_comments
      binding.eval([*magic, section.code].join("\n"), section.path, section.eval_start_line - magic.size)
    end

    def evaluate_expectations(test_case, context)
      evaluation_results = test_case.expectations.map do |expectation|
        ExpectationEvaluators::Registry
          .evaluator_for(expectation, test_case, context)
          .evaluate(context.result)
      end

      failing = test_case.expectations.each_index.find { |i| !evaluation_results[i][:passed] }

      {
        passed: failing.nil?,
        failure_index: failing,
        failure_line: failing && test_case.expectations[failing].line,
        actual_results: evaluation_results.map { |r| r[:actual] },
        expected_results: evaluation_results.map { |r| r[:expected] },
      }
    end

    # Setup, teardown and interludes. In fresh mode they run again for every
    # test (for_test is the test being prepared); their announcement and
    # output are shown on the first run only. A failure is reported whichever
    # run it happens on.
    #
    # A fresh-context teardown runs after every test but is announced once,
    # after the last one, the way a shared-context teardown is; its output
    # and any failure are shown under that announcement (see #report).
    #
    # What the section printed is collected in `output` even when it raises:
    # that is usually the diagnostic.
    def run_section(kind, section, binding, for_test = nil)
      return if section.nil? || section.empty?

      rerun         = @ran.key?(section)
      @ran[section] = true
      output        = +''

      announce_section(kind, section) unless rerun || deferred?(kind)
      capture_output(output) { eval_section(section, binding) }
      section_output(kind, output) unless rerun
    rescue *EXPECTABLE_ERRORS => ex
      section_failed(kind, section, ex, with_rerun_context(ex.message, rerun, for_test), output)
    rescue SystemExit, SignalException => ex
      message = "#{section_label(kind)} terminated by #{ex.class}: #{ex.message}"
      section_failed(kind, section, ex, with_rerun_context(message, rerun, for_test), output)
    end

    # Fresh context holds back what the teardown shows until it is announced.
    def deferred?(kind)
      kind == :teardown && !@shared
    end

    def report(kind, &display)
      return @teardown_report << display if deferred?(kind)

      yield
    end

    # A section that passed on its first run and fails on a later one says
    # which test it was preparing.
    def with_rerun_context(message, rerun, for_test)
      return message unless rerun && for_test

      "#{message} (when run again for test '#{for_test.description}')"
    end

    def announce_section(kind, section)
      case kind
      when :setup then @output_manager&.setup_start(section.line_range)
      when :teardown then @output_manager&.teardown_start(section.line_range)
      when :orphan then @output_manager&.info("Running orphan code block (#{location(section)})", 2)
      end
    end

    def announce_fresh_teardown
      return unless @ran.key?(@testrun.teardown)

      announce_section(:teardown, @testrun.teardown)
      @teardown_report.each(&:call)
    end

    def section_output(kind, output)
      return if output.empty?

      report(kind) do
        if kind == :teardown
          @output_manager&.teardown_output(output)
        else
          @output_manager&.setup_output(output)
        end
      end
    end

    # Setup and interlude failures abort the batch: every later test's state
    # is suspect. Teardown failures are reported and the batch completes; a
    # fresh-context teardown that fails after every test is reported once.
    def section_failed(kind, section, exception, message, output)
      @aborted ||= kind unless kind == :teardown
      return if @failed_sections.key?(section)

      @failed_sections[section] = true
      section_output(kind, output)

      @global_tally&.dig(:aggregator)&.add_infrastructure_failure(kind, @testrun.source_file, message, exception)

      Tryouts.debug "#{section_label(kind)} failed with #{Tryouts.classify_error(exception)} error: (#{exception.class}): #{exception.message}"
      Tryouts.trace exception.backtrace

      report(kind) do
        case kind
        when :setup
          @output_manager&.error("Global setup error: #{message}")
        when :orphan
          @output_manager&.error("Orphan code block failed (#{location(section)}): #{message}")
        when :teardown
          @output_manager&.error("Teardown failed: #{message}")
          @output_manager&.error('Continuing despite teardown failure')
        end
      end
    end

    def section_label(kind)
      { setup: 'Setup', teardown: 'Teardown', orphan: 'Orphan code block' }.fetch(kind)
    end

    def location(section)
      "#{section.path}:#{section.eval_start_line}"
    end

    # A setup failure is already counted as an infrastructure failure; an
    # interlude failure also counts against the file.
    def abort_batch
      reason         = @aborted == :setup ? 'setup failure' : 'orphan code block failure'
      @output_manager&.error("Stopping batch execution due to #{reason}")
      @status        = :failed
      @failed_count += 1 if @aborted == :orphan
      @output_manager&.file_end(path, context: context_name.to_sym, not_run: not_run_count)
      finalize_results
      false
    end

    # Test cases that never ran because the batch stopped early.
    def not_run_count
      size - @results.size
    end

    def build_test_result(test_case, context, expectations_result)
      factory = expectations_result[:passed] ? :from_success : :from_failure
      TestCaseResultPacket.public_send(
        factory,
        test_case,
        context.result,
        expectations_result[:actual_results],
        expectations_result[:expected_results],
        metadata: expectations_result.slice(:failure_index, :failure_line).compact,
      )
    end

    def build_error_result(test_case, exception)
      TestCaseResultPacket.from_error(test_case, exception)
    end

    def process_test_result(result, display)
      @results << result
      @global_tally&.dig(:aggregator)&.add_test_result(@testrun.source_file, result)
      @failed_count += 1 if result.failed? || result.error?

      return unless display

      @output_manager&.test_result(result)
      @output_manager&.test_output(result.test_case, result.captured_output, result) if result.has_output?
    end

    def finalize_results
      @status = :completed
    end

    def should_display_test_result?(test_case)
      return true unless @line_spec

      Tryouts::CLI::LineSpecParser.matches?(test_case, @line_spec)
    end

    # Redirects the process-global $stdout/$stderr for the duration of the
    # block and appends what was written (stdout, then stderr) to `output`,
    # whether or not the block raises. Returns the block's value. Used around
    # setup, teardown, interludes and every test, for display.
    def capture_output(output, &)
      out = StringIO.new
      err = StringIO.new
      capture_streams(out, err, &)
    ensure
      output << out.string << err.string
    end

    # Redirects $stdout to `out` and $stderr to `err` for the duration of the
    # block: for #=1> and #=2> (nested inside capture_output), and for
    # capture_output itself. The caller owns the buffers, so what was written
    # is there even when the block raises.
    def capture_streams(out, err)
      OUTPUT_CAPTURE_MONITOR.synchronize do
        old_stdout = $stdout
        old_stderr = $stderr
        begin
          $stdout = out
          $stderr = err
          yield
        ensure
          $stdout = old_stdout
          $stderr = old_stderr
        end
      end
    end

    def execute_with_timeout(test_case, &)
      Timeout.timeout(@test_timeout, DeadlineExceeded, &)
    rescue DeadlineExceeded
      Tryouts.debug "Test timeout after #{@test_timeout}s: #{test_case.description}"
      raise StandardError, "Test execution timeout (#{@test_timeout}s)"
    end

    def update_circuit_breaker(result)
      if result.failed? || result.error?
        @consecutive_failures += 1
        if @consecutive_failures >= @max_consecutive_failures
          @circuit_breaker_active = true
          Tryouts.debug "Circuit breaker activated after #{@consecutive_failures} consecutive failures"
        end
      else
        @consecutive_failures   = 0
        @circuit_breaker_active = false
      end
    end
  end
end
