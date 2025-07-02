# lib/tryouts/cli/formatters/verbose.rb

class Tryouts
  class CLI
    # Detailed formatter with line numbers and full context
    class VerboseFormatter
      include FormatterInterface

      def initialize(options = {})
        @line_width  = options.fetch(:line_width, 70)
        @show_passed = options.fetch(:show_passed, true)
      end

      def format_file_header(testrun)
        case testrun
        in { source_file: String => path }
          file_name      = File.basename(path)
          header_content = ">>>>>  #{file_name}  "
          padding        = '<' * (@line_width - header_content.length)

          [
            '-' * @line_width,
            header_content + padding,
            '-' * @line_width,
            '',
          ].join("\n")
        else
          ''
        end
      end

      def format_test_result(test_case, result_status, actual_results = [])
        case [test_case, result_status]
        in [Tryouts::PrismTestCase, :passed | :failed]
          output = build_test_output(test_case, result_status, actual_results)
          output.join("\n")
        else
          '# Invalid test case format'
        end
      end

      def format_summary(total_tests, failed_count, elapsed_time = nil)
        case [total_tests, failed_count]
        in [Integer => total, 0]
          success_summary(total, elapsed_time)
        in [Integer => total, Integer => failed] if failed > 0
          failure_summary(total, failed, elapsed_time)
        else
          'Summary unavailable'
        end
      end

      private

      def build_test_output(test_case, result_status, actual_results)
        description = test_case.description || ''
        output      = ['', "# #{description}"]

        source_lines = read_source_lines(test_case.path)
        test_lines   = parse_test_lines(test_case, source_lines)

        # Add code lines with line numbers
        code_output = format_code_lines(test_lines[:code])
        output.concat(code_output)

        # Add expectation lines with results
        expectation_output = format_expectation_lines(test_lines[:expectations], actual_results)
        output.concat(expectation_output)

        # Add status line
        status_line = format_status_line(test_case, result_status)
        output << status_line

        output
      end

      def parse_test_lines(test_case, source_lines)
        range             = test_case.line_range
        code_lines        = []
        expectation_lines = []

        range.each do |line_idx|
          next if line_idx >= source_lines.length

          line        = source_lines[line_idx]
          line_number = line_idx + 1

          case line
          in /^#\s*=>\s*(.*)/
            expectation_lines << { line_number: line_number, content: line, expectation: $1.strip }
          in /^##?\s*(.*)/ | /^#[^#=>]/ | /^\s*$/
            next # Skip descriptions, comments, blanks
          else
            unless line.strip.empty?
              code_lines << { line_number: line_number, content: line }
            end
          end
        end

        { code: code_lines, expectations: expectation_lines }
      end

      def format_code_lines(code_lines)
        code_lines.map { |line| format('%2d   %s', line[:line_number], line[:content]) }
      end

      def format_expectation_lines(expectation_lines, actual_results)
        expectation_lines.flat_map.with_index do |line_info, idx|
          expectation_line = format('%2d   %s', line_info[:line_number], line_info[:content])

          case actual_results[idx]
          in nil
            [expectation_line]
          in result
            result_str = result.inspect
            padding    = [@line_width - result_str.length, 10].max
            [expectation_line, (' ' * padding) + result_str]
          end
        end
      end

      def format_status_line(test_case, result_status)
        case [test_case.line_range.last, result_status]
        in [Integer => last_line, :passed]
          Console.color(:green, "PASSED @ #{test_case.path}:#{last_line + 1}")
        in [Integer => last_line, :failed]
          Console.color(:red, "FAILED @ #{test_case.path}:#{last_line + 1}")
        else
          'STATUS UNKNOWN'
        end
      end

      def read_source_lines(path)
        File.readlines(path).map(&:chomp)
      end

      def success_summary(total, elapsed_time)
        time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
        Console.color(:green, "All #{total} tests passed#{time_str}")
      end

      def failure_summary(total, failed, elapsed_time)
        passed   = total - failed
        time_str = elapsed_time ? " (#{elapsed_time.round(2)}s)" : ''
        Console.color(:red, "#{failed} of #{total} tests failed, #{passed} passed#{time_str}")
      end
    end

    # Verbose formatter that only shows failures
    class VerboseFailsFormatter < VerboseFormatter
      def initialize(options = {})
        super(options.merge(show_passed: false))
      end

      def format_test_result(test_case, result_status, actual_results = [])
        case result_status
        in :passed
          '' # Don't show passed tests
        in :failed | _
          super
        end
      end
    end
  end
end
