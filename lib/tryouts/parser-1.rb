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
QUERY_TEXT = "
  (source_file
    (metadata_declaration
      type: (identifier) @metadata_type
      value: (_) @metadata_value
    )*

    (setup_section
      (code_line)* @setup_code
      (instance_var_declaration)* @setup_vars
    )?

    (test_case
      (description
        text: (_) @description
      )*

      (code_block) @code

      (choice
        (expectation
          value: (_) @expectation_value
          status: (_)? @expectation_status
        )

        (expected_failure
          error_type: (_) @error_type
          message: (_)? @error_message
        )
      )+
    )*

    (teardown_section
      (code_line)* @teardown_code
    )?
  )
"

class Tryouts::Parser
  TestCase = Struct.new(:descriptions, :code, :expectations, :expected_failures, keyword_init: true)
  TestFile = Struct.new(:path, :metadata, :setup, :test_cases, :teardown, keyword_init: true)
  Expectation = Struct.new(:value, :status, keyword_init: true)
  ExpectedFailure = Struct.new(:error_type, :message, keyword_init: true)

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
      matches = cursor.matches

      metadata = {}
      setup = nil
      teardown = nil
      test_cases = []
      current_test = nil

      matches.each do |match|
        match.captures.each do |capture|
          case capture.name
          when 'metadata_type'
            type = extract_node_text(capture.node, source_code)
            value = extract_node_text(match.captures.find { |c| c.name == 'metadata_value' }&.node, source_code)
            metadata[type] = value if value
          when 'setup_code', 'setup_vars'
            setup_lines ||= []
            setup_lines << extract_node_text(capture.node, source_code)
            setup = setup_lines.compact.join("\n")
          when 'teardown_code'
            teardown = extract_node_text(capture.node, source_code)
          when 'description'
            if current_test.nil?
              current_test = TestCase.new(
                descriptions: [],
                code: nil,
                expectations: [],
                expected_failures: []
              )
            end
            desc = extract_node_text(capture.node, source_code)
            current_test.descriptions << desc.sub(/^##\s*/, '').strip if desc
          when 'code'
            if current_test
              current_test.code = extract_code(capture.node, source_code)
            end
          when 'expectation_value'
            if current_test
              value = extract_node_text(capture.node, source_code)
              status = extract_node_text(match.captures.find { |c| c.name == 'expectation_status' }&.node, source_code)

              # Clean up multi-line expectations
              value = value.gsub(/^\s*#\s*/, '')  # Remove leading # and whitespace
                         .gsub(/\n\s*#\s*/, "\n") # Remove # from continuation lines
                         .strip

              current_test.expectations << Expectation.new(value: value, status: status)
            end
          when 'error_type'
            if current_test
              error_type = extract_node_text(capture.node, source_code)
              message = extract_node_text(match.captures.find { |c| c.name == 'error_message' }&.node, source_code)
              current_test.expected_failures << ExpectedFailure.new(
                error_type: error_type,
                message: message
              )
            end
          end
        end

        # If we've processed all captures for this match and have a complete test case
        if current_test && current_test.code && (current_test.expectations.any? || current_test.expected_failures.any?)
          test_cases << current_test
          current_test = nil
        end
      end

      # Don't forget to add the last test case
      test_cases << current_test if current_test && current_test.code

      TestFile.new(
        path: path,
        metadata: metadata,
        setup: setup,
        test_cases: test_cases,
        teardown: teardown
      )
    rescue => e
      puts "Query error: #{e.message}"
      puts e.backtrace
      nil
    end
  end

  private

  def extract_code(node, source_code)
    return nil unless node
    # Get the raw code, excluding comments and expectations
    lines = node.text.split("\n").reject do |line|
      line.strip.start_with?('#') || line.strip.empty?
    end
    lines.join("\n")
  end

  def extract_node_text(node, source_code)
    return nil unless node
    source_code[node.start_byte...node.end_byte]
  end
end
