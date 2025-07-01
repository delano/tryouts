# lib/tryouts/verbose_formatter.rb

class Tryouts
  class VerboseFormatter
    def initialize(testrun, source_lines)
      @testrun = testrun
      @source_lines = source_lines
      @line_width = 80
    end

    def format_file_header
      file_name = File.basename(@testrun.source_file)
      header_content = ">>>>>  #{file_name}      "
      padding = "<" * (@line_width - header_content.length)

      [
        "-" * @line_width,
        header_content + padding,
        "-" * @line_width,
        ""
      ].join("\n")
    end

    def format_test_case(test_case, result, actual_results = [])
      output = []

      # Test description
      output << ""
      output << "# #{test_case.description}"

      # Parse the test case content to show line numbers
      test_lines = parse_test_case_lines(test_case)

      # Show code lines with line numbers
      test_lines[:code_lines].each do |line_info|
        line_num = line_info[:line_number]
        content = line_info[:content]
        output << sprintf("%2d   %s", line_num, content)
      end

      # Show expectations with line numbers and actual results
      test_lines[:expectation_lines].each_with_index do |line_info, idx|
        line_num = line_info[:line_number]
        content = line_info[:content]
        actual_result = actual_results[idx] if actual_results[idx]

        expectation_line = sprintf("%2d   %s", line_num, content)

        if actual_result
          # Right-align the actual result
          result_str = actual_result.inspect
          padding = @line_width - result_str.length
          padding = 10 if padding < 10  # Minimum padding

          output << expectation_line
          output << " " * padding + result_str
        else
          output << expectation_line
        end
      end

      # Status line
      last_expectation_line = test_lines[:expectation_lines].last
      if last_expectation_line
        status_location = "#{@testrun.source_file}:#{last_expectation_line[:line_number]}"
        status = result == :passed ? "PASSED" : "FAILED"
        status_color = result == :passed ? :green : :red

        output << Console.color(status_color, "#{status} @ #{status_location}")
      end

      output.join("\n")
    end

    private

    def parse_test_case_lines(test_case)
      start_line = test_case.line_range.first
      end_line = test_case.line_range.last

      code_lines = []
      expectation_lines = []

      # Scan through the test case range to find code and expectation lines
      (start_line..end_line).each do |line_idx|
        next if line_idx >= @source_lines.length

        line = @source_lines[line_idx]
        line_number = line_idx + 1  # 1-based line numbers

        case line
        when /^#\s*=>\s*(.*)/
          # This is an expectation line
          expectation_lines << {
            line_number: line_number,
            content: line,
            expectation: $1.strip
          }
        when /^##?\s*(.*)/
          # Skip description lines (already handled)
          next
        when /^#[^#=>]/
          # Skip regular comments
          next
        when /^\s*$/
          # Skip blank lines
          next
        else
          # This is a code line
          unless line.strip.empty?
            code_lines << {
              line_number: line_number,
              content: line
            }
          end
        end
      end

      {
        code_lines: code_lines,
        expectation_lines: expectation_lines
      }
    end
  end
end
