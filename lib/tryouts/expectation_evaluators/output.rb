# lib/tryouts/expectation_evaluators/output.rb

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
    # - String expectations: Uses String#include? for substring matching
    # - Regex expectations: Uses =~ operator for pattern matching
    # - Auto-detects expectation type based on content (literal string vs regex)
    # - Case-sensitive matching for both strings and regex patterns
    #
    # IMPLEMENTATION DETAILS:
    # - Requires output capture during test execution
    # - Expression has access to `result` and `_` variables (actual_result)
    # - Expected display shows the evaluated expression result
    # - Actual display shows captured output content for the specific pipe
    # - Supports evaluation of dynamic expressions in expectation content
    #
    # DESIGN DECISIONS:
    # - Uses POSIX pipe convention: 1=stdout, 2=stderr
    # - Always captures output for debugging regardless of expectations
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

      def evaluate(actual_result = nil, stdout_content = nil, stderr_content = nil)
        # Determine which pipe we're testing based on expectation metadata
        pipe_number = @expectation.respond_to?(:pipe) ? @expectation.pipe : 1

        # Get the appropriate captured content
        captured_content = case pipe_number
                          when 1 then stdout_content || ''
                          when 2 then stderr_content || ''
                          else ''
                          end

        # Create result packet for expression evaluation
        expectation_result = ExpectationResult.from_execution_with_output(actual_result, stdout_content, stderr_content)

        # Evaluate the expectation expression (could be string literal or regex)
        expected_pattern = eval_expectation_content(@expectation.content, expectation_result)

        # Determine matching strategy based on expectation type
        matched = case expected_pattern
                  when Regexp
                    # Regex pattern matching
                    !!(captured_content =~ expected_pattern)
                  when String
                    # String contains matching
                    captured_content.include?(expected_pattern)
                  else
                    # Convert to string and do contains check
                    captured_content.include?(expected_pattern.to_s)
                  end

        # Build result with appropriate pipe description
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
