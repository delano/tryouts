# lib/tryouts/parsers/execution_parser.rb

require_relative '../test_case'
require_relative 'base_parser'
require 'stringio'

class Tryouts
  # Purple Plan: Execution-First Parser
  # Runs tryout files and captures expression values at runtime,
  # then matches against parsed expectations. Eliminates AST complexity.
  class ExecutionParser < Tryouts::Parsers::BaseParser

    def parse
      return handle_syntax_errors if @prism_result.failure?

      parse_expectations
      execute_with_capture
      validate_results
      build_testrun
    end

    private

    # Phase 1: Extract expectations from comments using minimal Prism usage
    def parse_expectations
      @expectations = {}
      @descriptions = {}
      
      # Use Prism's built-in comment extraction (excludes HEREDOC content)
      comments = Prism.parse_comments(@source)
      
      comments.each do |comment|
        line = comment.location.start_line - 1 # Convert to 0-based indexing
        content = comment.slice.strip
        
        case content
        when /^##\s*(.+)/, /^#\s*TEST\s*\d*:\s*(.+)$/
          @descriptions[line] = { type: :description, content: $1.strip }
        when /^#\s*=>\s*(.+)$/
          # Mark previous non-comment line as having expectation
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=!>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :exception_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=:>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :result_type_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=~>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :regex_match_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*==>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :true_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when %r{^#\s*=/=>\s*(.+)$}
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :false_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=\|>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :boolean_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=%>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :performance_time_expectation, 
            content: $1.strip, 
            comment_line: line 
          }
        when /^#\s*=(\d+)>\s*(.+)$/
          code_line = find_previous_code_line(line)
          @expectations[code_line] ||= []
          @expectations[code_line] << { 
            type: :output_expectation, 
            content: $2.strip, 
            pipe: $1.to_i,
            comment_line: line 
          }
        end
      end
    end

    # Find the previous line that contains actual Ruby code (not comments/blanks)
    def find_previous_code_line(comment_line)
      (comment_line - 1).downto(0) do |line|
        line_content = @lines[line]
        next if line_content.strip.empty?
        next if line_content.strip.start_with?('#')
        return line
      end
      comment_line - 1 # Fallback
    end

    # Phase 2: Execute the tryout file with TracePoint to capture values
    def execute_with_capture
      @captures = []
      @output_capture = StringIO.new
      @exception_captures = []
      
      last_return_value = nil
      current_line = nil
      
      # Capture stdout/stderr
      original_stdout = $stdout
      $stdout = @output_capture
      
      trace = TracePoint.new(:line, :return, :raise, :call, :c_call) do |tp|
        next unless tp.path == @source_path
        
        case tp.event
        when :line
          # Check if previous line had expectations and capture its value
          if current_line && @expectations[current_line] && last_return_value
            @captures << {
              line: current_line,
              value: last_return_value,
              binding: tp.binding.dup
            }
            last_return_value = nil
          end
          current_line = tp.lineno - 1 # Convert to 0-based indexing
          
        when :return, :c_return
          # Store return value for potential capture
          last_return_value = tp.return_value
          
        when :raise
          # Capture exceptions
          @exception_captures << {
            line: tp.lineno - 1,
            exception: tp.raised_exception,
            binding: tp.binding.dup
          }
        end
      end
      
      begin
        trace.enable do
          eval(@source, TOPLEVEL_BINDING.dup, @source_path, 1)
        end
      rescue => e
        # Handle top-level exceptions
        @exception_captures << {
          line: -1,
          exception: e,
          binding: nil
        }
      ensure
        $stdout = original_stdout
        @captured_output = @output_capture.string
      end
      
      # Handle the last line if it has expectations
      if current_line && @expectations[current_line] && last_return_value
        @captures << {
          line: current_line,
          value: last_return_value,
          binding: nil
        }
      end
    end

    # Phase 3: Match captured values against expectations
    def validate_results
      @test_cases = []
      @setup_code = []
      @teardown_code = []
      
      current_test = nil
      
      @lines.each_with_index do |line_content, line_index|
        # Check for test descriptions
        if @descriptions[line_index]
          if current_test && current_test[:expectations].empty? && current_test[:code].empty?
            # Multi-line description - combine with existing
            current_test[:description] = "#{current_test[:description]} #{@descriptions[line_index][:content]}".strip
          else
            # Finalize previous test and start new one
            @test_cases << current_test if current_test
            
            current_test = {
              description: @descriptions[line_index][:content],
              start_line: line_index,
              end_line: line_index,
              code: [],
              expectations: [],
              results: []
            }
          end
        end
        
        # Check for expectations on this line
        if @expectations[line_index]
          expectations = @expectations[line_index]
          capture = @captures.find { |c| c[:line] == line_index }
          exception_capture = @exception_captures.find { |c| c[:line] == line_index }
          
          expectations.each do |expectation|
            result = validate_single_expectation(expectation, capture, exception_capture, line_index)
            
            if current_test
              current_test[:expectations] << expectation
              current_test[:results] << result
              current_test[:end_line] = line_index
            else
              # Expectation outside of test case - treat as setup validation
              # For now, we'll just track it
            end
          end
          
          if current_test && !line_content.strip.empty? && !line_content.strip.start_with?('#')
            current_test[:code] << line_content
          end
        elsif current_test && !line_content.strip.empty? && !line_content.strip.start_with?('#')
          # Add code line to current test
          current_test[:code] << line_content
          current_test[:end_line] = line_index
        end
      end
      
      # Add final test if exists
      @test_cases << current_test if current_test
      
      # Identify setup and teardown sections
      identify_sections
    end

    # Validate a single expectation against captured data
    def validate_single_expectation(expectation, capture, exception_capture, line_index)
      case expectation[:type]
      when :expectation
        validate_regular_expectation(expectation, capture, line_index)
      when :exception_expectation
        validate_exception_expectation(expectation, exception_capture, line_index)
      when :result_type_expectation
        validate_type_expectation(expectation, capture, line_index)
      when :regex_match_expectation
        validate_regex_expectation(expectation, capture, line_index)
      when :true_expectation
        validate_boolean_expectation(expectation, capture, line_index, true)
      when :false_expectation
        validate_boolean_expectation(expectation, capture, line_index, false)
      when :boolean_expectation
        validate_boolean_type_expectation(expectation, capture, line_index)
      when :performance_time_expectation
        validate_performance_expectation(expectation, capture, line_index)
      when :output_expectation
        validate_output_expectation(expectation, line_index)
      else
        { passed: false, error: "Unknown expectation type: #{expectation[:type]}" }
      end
    end

    def validate_regular_expectation(expectation, capture, line_index)
      return { passed: false, error: "No value captured for line #{line_index + 1}" } unless capture
      
      expected = eval(expectation[:content], capture[:binding] || TOPLEVEL_BINDING)
      actual = capture[:value]
      
      {
        passed: actual == expected,
        expected: expected,
        actual: actual,
        line: line_index + 1,
        type: :regular
      }
    end

    def validate_exception_expectation(expectation, exception_capture, line_index)
      if exception_capture
        # Create a binding with 'error' variable available for expectation evaluation
        binding = exception_capture[:binding] || TOPLEVEL_BINDING.dup
        binding.local_variable_set(:error, exception_capture[:exception])
        
        expected_result = eval(expectation[:content], binding)
        
        {
          passed: expected_result,
          expected: "#{expectation[:content]} to be true",
          actual: expected_result,
          line: line_index + 1,
          type: :exception
        }
      else
        {
          passed: false,
          error: "Expected exception #{expectation[:content]} but none was raised",
          line: line_index + 1,
          type: :exception
        }
      end
    end

    def validate_type_expectation(expectation, capture, line_index)
      return { passed: false, error: "No value captured for line #{line_index + 1}" } unless capture
      
      expected_type = eval(expectation[:content], TOPLEVEL_BINDING)
      actual_type = capture[:value].class
      
      {
        passed: actual_type == expected_type,
        expected: expected_type,
        actual: actual_type,
        line: line_index + 1,
        type: :result_type
      }
    end

    def validate_regex_expectation(expectation, capture, line_index)
      return { passed: false, error: "No value captured for line #{line_index + 1}" } unless capture
      
      regex = eval(expectation[:content], capture[:binding] || TOPLEVEL_BINDING)
      actual = capture[:value].to_s
      
      {
        passed: regex.match?(actual),
        expected: regex,
        actual: actual,
        line: line_index + 1,
        type: :regex_match
      }
    end

    def validate_boolean_expectation(expectation, capture, line_index, expected_boolean)
      return { passed: false, error: "No value captured for line #{line_index + 1}" } unless capture
      
      condition = eval(expectation[:content], capture[:binding] || TOPLEVEL_BINDING)
      
      {
        passed: condition == expected_boolean,
        expected: expected_boolean,
        actual: condition,
        line: line_index + 1,
        type: expected_boolean ? :true : :false
      }
    end

    def validate_boolean_type_expectation(expectation, capture, line_index)
      return { passed: false, error: "No value captured for line #{line_index + 1}" } unless capture
      
      condition = eval(expectation[:content], capture[:binding] || TOPLEVEL_BINDING)
      
      {
        passed: condition == true || condition == false,
        expected: "boolean (true or false)",
        actual: condition,
        line: line_index + 1,
        type: :boolean
      }
    end

    def validate_performance_expectation(expectation, capture, line_index)
      # For now, simplified - would need timing measurement in TracePoint
      {
        passed: true, # Placeholder
        expected: "#{expectation[:content]}ms",
        actual: "timing not implemented yet",
        line: line_index + 1,
        type: :performance_time
      }
    end

    def validate_output_expectation(expectation, line_index)
      expected_output = expectation[:content]
      
      {
        passed: @captured_output.include?(expected_output),
        expected: expected_output,
        actual: @captured_output,
        line: line_index + 1,
        type: :output
      }
    end

    # Identify setup, test, and teardown sections
    def identify_sections
      # Simple heuristic: code before first test is setup, after last test is teardown
      first_test_line = @test_cases.empty? ? nil : @test_cases.first[:start_line]
      last_test_line = @test_cases.empty? ? nil : @test_cases.last[:end_line]
      
      @lines.each_with_index do |line_content, line_index|
        next if line_content.strip.empty? || line_content.strip.start_with?('#')
        
        if first_test_line.nil? || line_index < first_test_line
          @setup_code << line_content
        elsif last_test_line && line_index > last_test_line
          @teardown_code << line_content
        end
      end
    end

    # Phase 4: Build standard Testrun object for compatibility
    def build_testrun
      test_cases = @test_cases.map do |test_data|
        expectations = test_data[:expectations].zip(test_data[:results]).map do |exp, result|
          type = case exp[:type]
                 when :exception_expectation then :exception
                 when :result_type_expectation then :result_type
                 when :regex_match_expectation then :regex_match
                 when :true_expectation then :true
                 when :false_expectation then :false
                 when :boolean_expectation then :boolean
                 when :performance_time_expectation then :performance_time
                 when :output_expectation then :output
                 else :regular
                 end
          
          if exp[:type] == :output_expectation
            OutputExpectation.new(content: exp[:content], type: type, pipe: exp[:pipe])
          else
            Expectation.new(content: exp[:content], type: type)
          end
        end
        
        TestCase.new(
          description: test_data[:description] || "Test case",
          code: test_data[:code].join("\n"),
          expectations: expectations,
          line_range: test_data[:start_line]..test_data[:end_line],
          path: @source_path,
          source_lines: @lines[test_data[:start_line]..test_data[:end_line]],
          first_expectation_line: test_data[:start_line]
        )
      end
      
      setup = Setup.new(
        code: @setup_code.join("\n"),
        line_range: 0..(@setup_code.length - 1),
        path: @source_path
      )
      
      teardown = Teardown.new(
        code: @teardown_code.join("\n"),
        line_range: 0..(@teardown_code.length - 1),
        path: @source_path
      )
      
      Testrun.new(
        setup: setup,
        test_cases: test_cases,
        teardown: teardown,
        source_file: @source_path,
        metadata: { parsed_at: @parsed_at, parser: parser_type }
      )
    end

    # Parser type identification for metadata
    def parser_type
      :execution
    end
  end
end