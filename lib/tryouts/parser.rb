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

    query_string = <<~QUERY
      (source_file
        (test_case
          code_block: (code_block) @code
          expectation: (expectation) @expectation
        ) @test_case
      )
    QUERY


    begin
      query = TreeSitter::Query.new(language, query_string)
      cursor = TreeSitter::QueryCursor.exec(query, root)
      matches = cursor.matches(query, root, source_code)
      test_cases = []
      current_test = nil
      current_test_node = nil
      current_expectations = []

      matches.each_capture_hash do |captures|
          require 'pry-byebug'; binding.pry;

        case_node = captures['test_case']
        code_node = captures['code']
        expect_node = captures['expectation']

        # If we see a new test case and have an existing one, save it
        if current_test && case_node != current_test_node
          test_cases << current_test
          current_expectations = []
        end
        pp [:case_node, case_node]
        pp [:current_test_node, current_test_node]
        pp [:current_test, current_test]

        # Start a new test case if we haven't seen this node before
        if case_node != current_test_node
          title = extract_title(code_node, source_code)
          code = extract_code(code_node, source_code)
          current_test = TestCase.new(title, code, [])
          current_test_node = case_node
        end

        # Add expectation to current test case
        if expect_node
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
    end
  end

  private

  def extract_title(code_node, source_code)
    # Look for comment lines starting with "## " or "# TEST"
    code_node.child_nodes.each do |node|
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
    lines = code_node.child_nodes.map do |node|
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
