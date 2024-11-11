require 'pathname'
require 'tree_sitter'
require 'pp'

# Get absolute path to the .so file
root_dir = Pathname.new(__dir__)
language_path = root_dir.join('build/Release/tree_sitter_ruby_tryouts.dylib')

begin
  # Load the compiled language with name and path
  language = TreeSitter::Language.load('ruby_tryouts', language_path.to_s)

  # Create a parser
  parser = TreeSitter::Parser.new
  parser.language = language

  # Parse a file
  source_path = root_dir.join('../try/step1_try.rb')
  source_code = File.read(source_path)

  # Try parsing with source code directly
  tree = parser.parse_string(nil, source_code)
  root = tree.root_node

  query_string = '(test_case
    (code_block) @code
    (expectation) @expect)'
  query = TreeSitter::Query.new(language, query_string)
  puts "query: pattern count: #{query.pattern_count}"

  # Iterate over all the matches in the order they were found
  cursor = TreeSitter::QueryCursor.exec(query, root)
  puts '  matches:'
  while match = cursor.next_match
    puts "    #{match.capture_count} captured"
    puts '    ['
    puts match.captures.map { |c| "      #{c}" }.join("\n")
    puts '    ]'
  end


  # 1. Print node structure with indentation
#def print_tree(node, level = 0)
#  indent = "  " * level
#  puts "#{indent}#{node.type}: '#{node.source_text}'"
#  node.named_children.each { |child| print_tree(child, level + 1) }
#end
#print_tree(tree.root_node)
#
## 2. Query-based traversal
#query_string = '(test_case
#  (code_block) @code
#  (expectation) @expect)'
#query = language.query(query_string)
#matches = query.matches(root)
#
#matches.each do |match|
#  code = match.captures.find { |c| c.name == 'code' }
#  expect = match.captures.find { |c| c.name == 'expect' }
#  puts "Code: #{code.text}"
#  puts "Expectation: #{expect.text}"
#end

## 3. Cursor-based traversal
#cursor = TreeSitter::TreeCursor.new(tree.root_node)
#loop do
#  puts "#{cursor.type}: #{cursor.node.text}"
#  break unless cursor.goto_next_sibling
#end
#
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
  exit 1
rescue => e
  puts "Error loading language: #{e.message}"
  puts e.backtrace
  exit 1
end


__END__
require 'tree_sitter'

parser = TreeSitter::Parser.new
language = TreeSitter::Language.load('javascript', 'path/to/libtree-sitter-javascript.{so,dylib}')
# Or simply
language = TreeSitter.lang('javascript')
# Which will try to look in your local directory and the system for installed parsers.
# See TreeSitter::Mixin::Language#lib_dirs

src = "[1, null]"

parser.language = language

tree = parser.parse_string(nil, src)
root = tree.root_node

root.each do |child|
  # ...
end
