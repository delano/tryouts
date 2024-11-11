# Load required gems
require 'pathname'
require 'tree_sitter'
require 'pp'

# Get absolute path to the .so file
root_dir = Pathname.new(TRYOUTS_LIB_HOME).join('..')
language_path = root_dir.join('tree-sitter-grammar/build/Release/tree_sitter_ruby_tryouts.dylib')

begin
  # Load the compiled language with name and path
  language = TreeSitter::Language.load('ruby_tryouts', language_path.to_s)
  parser = TreeSitter::Parser.new
  parser.language = language

  # Parse source file
  source_path = root_dir.join('try/step1_try.rb')
  source_code = File.read(source_path)
  tree = parser.parse_string(nil, source_code)
  root = tree.root_node

  # Query-based traversal with proper text extraction
  query_string = '(test_case
    (code_block) @code
    (expectation) @expect)'

  query = language.query(query_string)
  matches = query.matches(root)

  matches.each do |match|
    code_node = match.captures.find { |c| c.name == 'code' }&.node
    expect_node = match.captures.find { |c| c.name == 'expect' }&.node

    if code_node && expect_node
      code_text = source_code[code_node.start_byte...code_node.end_byte]
      expect_text = source_code[expect_node.start_byte...expect_node.end_byte]

      puts "\nTest Case:"
      puts "Code:\n#{code_text}"
      puts "Expectation:\n#{expect_text}"
      puts "-" * 40
    end
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end
