require "tree_sitter"
require "tree_sitter/ruby"

class Tryouts::Parser
  def initialize(language_path)
    @language = TreeSitter::Language.load('ruby_tryouts', language_path)
    @parser = TreeSitter::Parser.new
    @parser.language = @language

    # Define reusable queries for each node type
    @queries = {
      metadata: @language.query(<<~QUERY),
        (metadata_declaration
          type: (_) @type
          value: (_) @value) @declaration
      QUERY

      test_case: @language.query(<<~QUERY),
        (test_case
          description: (description text: (_) @desc)*
          code_block: (code_block) @code
          expectation: (expectation value: (_) @value status: (_)? @status)*
          expected_failure: (expected_failure
            error_type: (_) @error_type
            message: (_)? @message)*) @case
      QUERY
    }
  end

  def parse_file(path)
    source = File.read(path)
    tree = @parser.parse(source)

    # Execute queries instead of manual traversal
    metadata = execute_metadata_query(tree)
    test_cases = execute_test_case_query(tree)

    TestSuite.new(
      metadata: metadata,
      test_cases: test_cases
    )
  end

  private

  def execute_metadata_query(tree)
    metadata = {}
    matches = @queries[:metadata].matches(tree.root_node)

    matches.each do |match|
      type = match["type"].text
      value = match["value"].text
      metadata[type] = value
    end
    metadata
  end
end
