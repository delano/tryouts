# lib/tryouts/translators/example_run.rb
#
# frozen_string_literal: true

require 'stringio'
require_relative '../test_batch'
require_relative 'eval_source'

class Tryouts
  module Translators
    # One test case run by --rspec or --minitest, judged the way direct mode
    # judges it. The test code runs once in the example's binding, then every
    # expectation goes through the evaluator direct mode uses
    # (ExpectationEvaluators::Registry) against what the code produced:
    # result, error, elapsed time, stdout and stderr. So each operator passes
    # or fails as it does in direct mode, and a malformed or detached
    # expectation fails.
    class ExampleRun
      # A binding whose self is object and whose scope is the top level, the
      # way direct mode evaluates a file (see ScriptBinding): no local
      # variables, a constant or class the code defines is top-level, and a
      # `def` is a singleton method of object. For RSpec, whose setup runs
      # on another object than the examples.
      def self.top_level_binding(object)
        object.instance_eval(&TOP_LEVEL)
      end

      # The same for a class body: self is klass and a `def` is an instance
      # method of klass, so the examples can call it.
      def self.top_level_class_binding(klass)
        klass.class_eval(&TOP_LEVEL)
      end

      # A binding whose self is object, with no local variables, where a
      # constant or `def` belongs to object's singleton class and constants
      # of object's class are in scope. For Minitest, whose setup runs on
      # the test's own object and whose interludes are in the test class.
      def self.instance_binding(object)
        object.instance_eval(&INSTANCE)
      end

      def initialize(testrun, test_case, binding)
        @testrun   = testrun
        @test_case = test_case
        @binding   = binding
      end

      # Runs the test code, then yields, for each expectation in order,
      # whether it passed and, when it did not, a message saying what it
      # expected and got. The message is built only then, so a passing
      # check never calls inspect on the values.
      def each_outcome
        context = run_code
        @test_case.expectations.each do |expectation|
          evaluator = ExpectationEvaluators::Registry.evaluator_for(expectation, @test_case, context)
          outcome   = evaluator.evaluate(context.result)
          yield outcome[:passed], (failure_message(expectation, outcome) unless outcome[:passed])
        end
      end

      private

      # As TestBatch#run_test_code: an error the test is not expected to
      # raise propagates, and the example errors. Output goes to binary
      # buffers and is read as UTF-8 with invalid bytes replaced, as
      # TestBatch reads it.
      def run_code
        value  = nil
        error  = nil
        stdout = @test_case.expectations.any?(&:output?) ? StringIO.new(''.b) : nil
        stderr = stdout && StringIO.new(''.b)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
        begin
          value = stdout ? capture_streams(stdout, stderr) { eval_code } : eval_code
        rescue TestBatch::ProgramError => ex
          raise unless expects_error?(ex)

          error = ex
        end
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) - started

        ExpectationEvaluators::EvaluationContext.new(
          binding: @binding,
          path: @test_case.path,
          magic_comments: @testrun.magic_comments,
          result: error || value,
          error: error,
          elapsed_ns: elapsed,
          stdout: stdout && TestBatch.captured_text(stdout),
          stderr: stderr && TestBatch.captured_text(stderr),
        )
      end

      def eval_code
        @binding.eval(*EvalSource.section(@testrun, @test_case))
      end

      # As TestBatch#expects_error?
      def expects_error?(error)
        return true if @test_case.exception_expectations?

        error.is_a?(StandardError) && @test_case.expectations.any? { |exp| exp.result_type? || exp.regex_match? }
      end

      def capture_streams(out, err)
        TestBatch::OUTPUT_CAPTURE_MONITOR.synchronize do
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

      def failure_message(expectation, outcome)
        line = expectation.line ? ":#{expectation.line + 1}" : ''
        "#{@test_case.path}#{line}: expected #{outcome[:expected].inspect}, got #{outcome[:actual].inspect}"
      end
    end
  end
end

# Blocks written at the top level of this file, so a binding taken inside
# one has no local variables. TOP_LEVEL keeps the top-level lexical scope
# whatever self instance_eval or class_eval gives it; INSTANCE takes the
# scope a string instance_eval gives, self's singleton class.
Tryouts::Translators::ExampleRun.const_set(:TOP_LEVEL, proc { binding })
Tryouts::Translators::ExampleRun.const_set(:INSTANCE, proc { instance_eval('binding', __FILE__, __LINE__) })
Tryouts::Translators::ExampleRun.private_constant(:TOP_LEVEL, :INSTANCE)
