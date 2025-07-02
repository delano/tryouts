# lib/tryouts/prism_parser.rb

require 'prism'
require_relative 'data_structures'

class Tryouts
  # PrismParser transforms Ruby test files into structured test data using Prism AST parsing.
  #
  # Operation order:
  # 1. Initialize with source file path
  # 2. Read source and parse with Prism
  # 3. Line-by-line state machine parsing
  # 4. Build structured test cases with proper line ranges
  # 5. Return Testrun object with setup/tests/teardown
  class PrismParser
    def initialize(source_path)
      @source_path = source_path
      @source      = File.read(source_path)
      @lines       = @source.lines.map(&:chomp)  # Remove trailing newlines for clean processing
      @result      = Prism.parse(@source)        # Parse Ruby source into AST for syntax validation
    end

    # Main parsing entry point. Returns Testrun object or raises syntax errors.
    def parse
      return handle_syntax_errors if @result.failure?

      parse_tryouts_structure
    end

    private

    # Core parsing logic using a state machine approach.
    # States: :setup (initial), :test (parsing test cases)
    # Processes each line to build setup, test cases, and teardown sections.
    def parse_tryouts_structure
      state          = :setup    # Start in setup phase
      current_test   = nil       # Currently building test case
      setup_lines    = []        # Code before first test
      test_cases     = []        # Completed test cases
      teardown_lines = []        # Code after last test

      @lines.each_with_index do |line, index|
        line_type, content = parse_line(line)

        # Pattern matching on [state, line_type] tuples (Ruby 3.0+ feature)
        # This replaces nested if/elsif chains with cleaner match expressions
        case [state, line_type]
        in [:setup, :description]
          # Transition from setup to test phase on first test description
          state        = :test
          current_test = init_test_case(content, index)
        in [:setup, :potential_description]
          # Check if this looks like a filename comment or should be treated as setup
          if looks_like_filename_comment?(content, index)
            setup_lines << line
          else
            # Treat as description in setup phase - transition to test
            state        = :test
            current_test = init_test_case(content, index)
          end
        in [:test, :description]
          # Handle multiple descriptions: combine if test is empty, otherwise finalize current test
          if current_test && current_test[:code].empty? && current_test[:expectations].empty?
            current_test[:description] << content
          else
            test_cases << build_test_case(current_test) if current_test
            current_test = init_test_case(content, index)
          end
        in [:test, :potential_description]
          # If current test has code but no expectations yet, treat as comment within test
          if current_test && !current_test[:code].empty? && current_test[:expectations].empty?
            current_test[:code] << line
          # If current test has expectations, finalize it and start new test
          elsif current_test && !current_test[:expectations].empty?
            test_cases << build_test_case(current_test)
            current_test = init_test_case(content, index)
          # If current test has no content, combine descriptions
          elsif current_test && current_test[:code].empty? && current_test[:expectations].empty?
            current_test[:description] << content
          else
            # Start new potential test case
            test_cases << build_test_case(current_test) if current_test
            current_test = init_test_case(content, index)
          end
        in [:test, :code]
          current_test[:code] << line if current_test
        in [:test, :expectation]
          current_test[:expectations] << content if current_test
        in [:setup, :code]
          setup_lines << line
        in [:test, :blank | :comment]
          add_to_current_context(line, state, current_test, setup_lines)
        else
          handle_unknown_line(line, state, index)
        end
      end

      test_cases << build_test_case(current_test) if current_test

      # Filter out test cases that don't meet minimum requirements (description + expectation)
      valid_test_cases = test_cases.select do |test_case|
        !test_case.description.strip.empty? && !test_case.expectations.empty?
      end

      # Detect teardown: lines after last test case
      teardown_lines = detect_teardown_lines(valid_test_cases)

      Testrun.new(
        setup: build_setup(setup_lines),
        test_cases: valid_test_cases,
        teardown: build_teardown(teardown_lines),
        source_file: @source_path,
        metadata: { parsed_at: Time.now, parser: :prism },
      )
    end

    # Line classification using pattern matching (Ruby 3.0+ feature).
    # Returns [line_type, content] tuple for state machine processing.
    #
    # Line types:
    # - :description     - ## Test description (starts new test)
    # - :expectation     - # => Expected output
    # - :potential_desc  - # Possible description (context-dependent)
    # - :comment         - # Regular comment
    # - :blank          - Empty line
    # - :code           - Executable Ruby code
    def parse_line(line)
      case line
      in /^##\s*(.*)/ if ::Regexp.last_match(1)                                    # ## Description
        [:description, ::Regexp.last_match(1).strip]
      in /^##?\s*TEST\s+\d+:\s*(.*)/ if ::Regexp.last_match(1)                    # ## TEST 1: Description
        [:description, ::Regexp.last_match(1).strip]
      in /^#\s*=>\s*(.*)/ if ::Regexp.last_match(1)                               # # => expectation
        [:expectation, ::Regexp.last_match(1).strip]
      in /^#\s+(.*)/ if ::Regexp.last_match(1) && !::Regexp.last_match(1).strip.empty?  # # potential description
        [:potential_description, ::Regexp.last_match(1).strip]
      in /^#[^#=>](.*)/ if ::Regexp.last_match(1)                                 # # comment
        [:comment, ::Regexp.last_match(1).strip]
      in /^\s*$/                                                                   # blank line
        [:blank, nil]
      else                                                                         # executable code
        [:code, line]
      end
    end

    # Heuristic to distinguish filename comments from test descriptions.
    # Prevents treating "# filename.rb" as a test case description.
    def looks_like_filename_comment?(content, line_index)
      # Filename comments typically:
      # 1. Are at the beginning of the file (within first few lines)
      # 2. Contain file extensions like .rb
      # 3. Don't contain test-related language
      return true if line_index < 3 && content.match?(/\.(rb|py|js|ts|java|cpp|c)$/)
      return true if line_index == 0 # First line is often a filename comment

      false
    end

    # Initialize test case hash with tracking for multi-line descriptions.
    # Using arrays allows accumulation of multiple description lines.
    def init_test_case(description, line_index)
      {
        description: [description],     # Array to collect multiple description lines
        code: [],                      # Array to collect code lines
        expectations: [],              # Array to collect expectation lines
        line_start: line_index,        # Track starting line for range calculation
      }
    end

    # Convert accumulated test data hash into PrismTestCase object.
    # Calculates precise line ranges for accurate source mapping.
    def build_test_case(test_data)
      return nil unless test_data

      # Calculate proper end line for this test case
      start_line = test_data[:line_start]
      end_line   = find_test_end_line_from_data(test_data, start_line)
      line_range = start_line..end_line

      PrismTestCase.new(
        description: test_data[:description].join(' ').strip,  # Flatten multi-line descriptions
        code: test_data[:code].join("\n"),                     # Reconstruct code block
        expectations: test_data[:expectations],                # Keep expectations as array
        line_range: line_range,                                # Range object for source mapping
        path: @source_path,
      )
    end

    # Calculate precise end line by scanning forward until next test or EOF.
    # Essential for accurate line range mapping in test execution.
    def find_test_end_line_from_data(test_data, start_line)
      # Find the last line that belongs to this test case
      # Look for the last expectation or code line before the next test or end of file

      current_line      = start_line
      last_content_line = start_line

      # Scan forward using array slicing (Ruby idiom: negative indices for "rest of array")
      @lines[(start_line + 1)..-1].each_with_index do |line, offset|
        line_index = start_line + 1 + offset
        line_type, = parse_line(line)

        case line_type
        when :description, :potential_description
          # Found next test case, stop here
          break
        when :expectation, :code
          # This line belongs to current test case
          last_content_line = line_index
        when :comment, :blank
          # Skip comments and blanks, but don't update last_content_line
          next
        end
      end

      last_content_line
    end

    # Create Setup object from accumulated setup lines.
    # Uses keyword arguments (Ruby 2.1+ feature) for clear parameter naming.
    def build_setup(lines)
      return Setup.new(code: '', line_range: 0..0, path: @source_path) if lines.empty?

      Setup.new(
        code: lines.join("\n"),                    # Reconstruct multi-line setup code
        line_range: 0..(lines.size - 1),          # Range from start of file
        path: @source_path,
      )
    end

    # Create Teardown object with calculated line ranges from end of file.
    # Line range calculation ensures proper source mapping for teardown code.
    def build_teardown(lines)
      return Teardown.new(code: '', line_range: 0..0, path: @source_path) if lines.empty?

      start_line = @lines.size - lines.size       # Calculate teardown start position
      Teardown.new(
        code: lines.join("\n"),                   # Reconstruct teardown code
        line_range: start_line..(@lines.size - 1), # Range to end of file
        path: @source_path,
      )
    end

    def add_to_current_context(line, state, current_test, setup_lines)
      case state
      when :setup
        setup_lines << line unless line.strip.empty?
      when :test
        current_test[:code] << line if current_test
      end
    end

    def handle_unknown_line(line, state, index)
      # For now, treat unknown lines as code
    end

    # Detect teardown section using explicit markers or implicit detection.
    # Uses method chaining and safe navigation for robust line range calculation.
    def detect_teardown_lines(test_cases)
      return [] if test_cases.empty?

      # Look for explicit teardown marker comment
      teardown_start = @lines.find_index do |line|
        line.match?(/^#.*teardown/i)              # Case-insensitive teardown detection
      end

      if teardown_start
        # Everything after teardown marker, filtered using block shorthand (&:empty?)
        @lines[(teardown_start + 1)..-1].reject(&:empty?)
      else
        # Fallback: use method chaining to find last test end line
        last_test_end_line = test_cases.map(&:line_range).map(&:last).max || 0
        return [] if last_test_end_line >= @lines.size - 1

        @lines[(last_test_end_line + 1)..-1]     # Array slice from last test to EOF
      end
    end

    def find_test_case_end_line(test_case)
      # Simple approach: find last non-blank line before next test or end of file
      test_start = test_case.line_range.first

      # Look for next test case description
      next_test_line = @lines[(test_start + 1)..-1].find_index do |line|
        line_type, = parse_line(line)
        line_type == :description
      end

      if next_test_line
        actual_next_line = test_start + 1 + next_test_line
        actual_next_line - 1
      else
        @lines.size - 1
      end
    end

    # Convert Prism syntax errors into domain-specific TryoutSyntaxError objects.
    # Uses safe array access with || fallback for robust error context extraction.
    def handle_syntax_errors
      errors = @result.errors.map do |error|
        TryoutSyntaxError.new(
          error.message,
          line_number: error.location.start_line,
          context: @lines[error.location.start_line - 1] || '',  # Safe array access
          source_file: @source_path,
        )
      end

      raise errors.first if errors.any?            # Raise first error to halt execution
    end
  end
end
