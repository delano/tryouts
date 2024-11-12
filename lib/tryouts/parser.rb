
#
#   The query captures:
#
#   1. File-level metadata:
#      - Type (requires, version, ruby, at, timezone)
#      - Value
#
#   2. Identify Setup and Teardown sections
#
#   3. For each test case:
#      - All description lines
#      - Code block
#      - Multiple expectations with:
#        - Value (single or multi-line)
#        - Optional status (pass/fail)
#      - Expected failures with:
#        - Error type
#        - Optional error message
#
#   This structure allows Tryouts to:
#   1. Set up the environment based on metadata
#   2. Execute each test with proper context
#   3. Handle both successful and error cases
#   4. Support multiple assertions per test
#   5. Provide rich failure messages
#   6. Execute setup code first
#   7. Run test cases in sequence
#   8. Execute teardown code last
#   9. Maintain instance variables across the entire batch
#
QUERY_TEXT = <<~QUERY
  (source_file
    metadata: (metadata_declaration
      type: _ @metadata_type
      value: _ @metadata_value
    )*

    setup: (setup_section
      (code_line)* @setup_code
      (instance_var_declaration)* @setup_vars
    )?

    (test_case
      description: (description
        text: _ @description
      )*

      code_block: (code_block) @code

      (choice
        expectation: (expectation
          value: _ @expectation_value
          status: _ @expectation_status?
        )

        expected_failure: (expected_failure
          error_type: _ @error_type
          message: _ @error_message?
        )
      )+
    ) @test_case

    teardown: (teardown_section
      (code_line)* @teardown_code
    )?
  ) @source_file
QUERY

class Tryouts::Parser
  TestCase = Struct.new(:title, :code, :expectations)
  TestFile = Struct.new(:path, :test_cases)

  attr_reader :language

  def initialize(language_path)
    @language = TreeSitter::Language.load('ruby_tryouts', language_path.to_s)
    @parser = TreeSitter::Parser.new
    @parser.language = @language
  end

  def parse_file(path)
    source_code = File.read(path)
    tree = @parser.parse_string(nil, source_code)
    root = tree.root_node


    begin
      query = TreeSitter::Query.new(language, QUERY_TEXT)
      cursor = TreeSitter::QueryCursor.exec(query, root)
      matches = cursor.matches(query, root, source_code)
      test_cases = []
      current_test = nil
      current_test_node = nil

      matches.each_capture_hash do |captures|
        case_node = captures['test_case']
        code_node = captures['code']
        expect_node = captures['expectation']

        next unless case_node && code_node # Skip if essential nodes are missing

        # Check if this is a new test case
        is_new_test = current_test_node.nil? ||
                      (case_node && current_test_node && case_node.id != current_test_node.id)

        if is_new_test
          # Save previous test case if it exists
          test_cases << current_test if current_test

          # Create new test case
          title = extract_title(code_node, source_code)
          code = extract_code(code_node, source_code)
          current_test = TestCase.new(title, code, [])
          current_test_node = case_node
        end

        # Add expectation to current test case if we have both
        if current_test && expect_node
          expectation = extract_expectation(expect_node, source_code)
          current_test.expectations << expectation
        end
      end

      # Don't forget to add the last test case
      test_cases << current_test if current_test

      TestFile.new(path, test_cases)
    rescue => e
      puts "Query error: #{e.message}\nQuery: #{query_string}"
      puts e.backtrace
      nil
    end
  end

  private
  def extract_title(code_node, source_code)
    # Look for comment lines starting with "## " or "# TEST"
    code_node.each do |node|
      if node.type.to_s == 'comment'
        text = extract_node_text(node, source_code)
        if text.match?(/^#\s*TEST|^##\s+/)
          return text.sub(/^#*\s*/, '').strip
        end
      end
    end
    nil
  end

  def extract_code(code_node, source_code)
    # Filter out comments and get only actual code lines
    lines = code_node.map do |node|
      if node.type.to_s == 'code_line'
        extract_node_text(node, source_code)
      end
    end
    lines.compact.join("\n")
  end

  def extract_expectation(expect_node, source_code)
    text = extract_node_text(expect_node, source_code)
    # Remove the #=> or # => prefix and trim
    text.sub(/^#\s*=>\s*/, '').strip
  end

  def extract_node_text(node, source_code)
    source_code[node.start_byte...node.end_byte].strip
  end
end
