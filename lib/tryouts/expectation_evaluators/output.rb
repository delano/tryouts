# lib/tryouts/expectation_evaluators/output.rb
#
# frozen_string_literal: true

require_relative 'base'

class Tryouts
  module ExpectationEvaluators
    # Evaluator for output expectations using syntax: #=1> content, #=2> content
    #
    # PURPOSE:
    # - Validates that stdout (pipe 1) or stderr (pipe 2) contains expected content
    # - Provides ability to test console output, error messages, and logging
    # - Supports both string contains and regex pattern matching
    #
    # SYNTAX:
    # - #=1> expression  - Test stdout content
    # - #=2> expression  - Test stderr content
    #
    # Examples:
    #   puts "Hello World"           #=1> "Hello"            # String contains check
    #   puts "Hello World"           #=1> /Hello.*World/     # Regex pattern match
    #   $stderr.puts "Error!"        #=2> "Error"            # Stderr contains check
    #   $stderr.puts "Warning: 404"  #=2> /Warning.*\d+/     # Stderr regex match
    #
    # MATCHING BEHAVIOR:
    # - The expression is evaluated first; a Regexp is matched with
    #   String#match?, anything else is converted with to_s and tested with
    #   String#include? (a String is a substring test, not an exact match)
    # - Case-sensitive matching for both strings and regex patterns
    #
    # IMPLEMENTATION DETAILS:
    # - stdout and stderr are captured separately only for tests that have a
    #   #=1> or #=2> expectation
    # - Output written before a raise is kept, so a #=!> test can also check
    #   what it printed
    # - Expression is evaluated in the test's binding: it sees the test's
    #   locals, plus `result`/`_` (the test value), `error` and `elapsed_ms`
    # - Expected display shows the evaluated expression result
    # - Actual display shows captured output content for the specific pipe
    #
    # DESIGN DECISIONS:
    # - Uses POSIX pipe convention: 1=stdout, 2=stderr
    # - Every test's combined output is also captured for display, regardless
    #   of expectations
    # - Supports both literal strings and regex patterns seamlessly
    # - Part of unified #= prefix convention for all expectation types
    # - Uses #=N> syntax where N is the pipe number (following shell convention)
    #
    # PIPE MAPPING:
    # - Pipe 1: Standard output (stdout) - $stdout, puts, print, p
    # - Pipe 2: Standard error (stderr) - $stderr, warn, STDERR.puts
    # - Future pipes (3+) could support custom streams if needed
    class Output < Base
      def self.handles?(expectation_type)
        expectation_type == :output
      end

      def evaluate(actual_result = nil)
        pipe_number = @expectation.respond_to?(:pipe) ? @expectation.pipe : 1

        captured_content = case pipe_number
                           when 1 then @context.stdout || ''
                           when 2 then @context.stderr || ''
                           else ''
                           end

        expected_pattern = evaluate_expression

        matched = case expected_pattern
                  when Regexp
                    captured_content.match?(expected_pattern)
                  else
                    captured_content.include?(expected_pattern.to_s)
                  end

        pipe_name = case pipe_number
                    when 1 then 'stdout'
                    when 2 then 'stderr'
                    else "pipe#{pipe_number}"
                    end

        build_result(
          passed: matched,
          actual: "#{pipe_name}: #{captured_content.inspect}",
          expected: expected_pattern.inspect,
          expectation: @expectation.content,
        )
      rescue StandardError => ex
        handle_evaluation_error(ex, actual_result)
      end
    end
  end
end
