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

    # Query matches the actual grammar structure
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

      test_cases = []

      while match = cursor.next_match
        test_nodes = match.captures.map(&:node)
        test_nodes.each do |test_node|
          if test_node.type.to_s == 'test_case'
            code_block = test_node.child_by_field_name('code_block')
            expect_node = test_node.child_by_field_name('expectation')

            if code_block && expect_node
              # Extract full text of the code block
              code_block_text = extract_node_text(code_block, source_code)

              # Extract expectation text
              expectation_text = extract_node_text(expect_node, source_code)

              puts "Code Block:"
              puts code_block_text
              puts "Expectation:"
              puts expectation_text
            end
          end
        end
      end

      TestFile.new(path, test_cases)
    rescue => e
      raise "Query error: #{e.message}\nQuery: #{query_string}"
    end
  end

  private

  def extract_text(node, source_code)
    return nil unless node
    source_code[node.start_byte...node.end_byte].strip
  end

  def extract_node_text(node, source_code)
    # Get the byte range of the node
    start_byte = node.start_byte
    end_byte = node.end_byte

    # Extract text from source code using the byte range
    source_code[start_byte...end_byte]
  end
end
