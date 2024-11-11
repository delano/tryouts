require 'pathname'
require 'tree_sitter'

unless defined?(TRYOUTS_LIB_HOME)
  TRYOUTS_LIB_HOME = File.expand_path File.dirname(__FILE__)
end

class Tryouts
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    alias_method :inspect, :to_s
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(TRYOUTS_LIB_HOME, '..', 'VERSION.yml'))
    end
  end
end

class Tryouts
  @debug = false
  @quiet = false
  @noisy = false
  @container = Class.new
  @cases = []
  @sysinfo = nil

  class << self
    attr_accessor :debug, :container, :quiet, :noisy
    attr_reader :cases
  end

  module ClassMethods

    def sysinfo
      require 'sysinfo'
      @sysinfo ||= SysInfo.new
      @sysinfo
    end

    def debug?() @debug == true end
  end

  extend ClassMethods
end

class Tryouts::Parser
  TestCase = Struct.new(:title, :code, :expectations)
  TestFile = Struct.new(:path, :test_cases)

  def initialize(language_path)
    @language = TreeSitter::Language.load('ruby_tryouts', language_path.to_s)
    @parser = TreeSitter::Parser.new
    @parser.language = @language
  end

  def parse_file(path)
    source_code = File.read(path)
    tree = @parser.parse_string(nil, source_code)

    require 'pry-byebug'; binding.pry;

    # Query to find test cases with their components
    query_string = <<~QUERY
      (source_file
        (test_case
          (code_block) @code
          (expectation) @expect)*)
    QUERY

    query = @language.query(query_string)
    matches = query.matches(tree.root_node)

    test_cases = matches.map do |match|
      code_node = match.captures.find { |c| c.name == 'code' }&.node
      expect_nodes = match.captures.select { |c| c.name == 'expect' }.map(&:node)

      next unless code_node

      # Extract title from comments
      title = extract_title(code_node, source_code)
      code = extract_code(code_node, source_code)
      expectations = extract_expectations(expect_nodes, source_code)

      TestCase.new(title, code, expectations)
    end.compact

    TestFile.new(path, test_cases)
  end

  private

  def extract_title(code_node, source)
    # Look for first comment in code block
    comment_query = @language.query('(comment) @comment')
    matches = comment_query.matches(code_node)
    first_comment = matches.first&.captures&.first&.node

    if first_comment
      text = source[first_comment.start_byte...first_comment.end_byte]
      text.gsub(/^#\s*/, '').strip
    else
      "Untitled Test"
    end
  end

  def extract_code(node, source)
    # Get all code lines excluding comments
    code_query = @language.query('(code_line) @code')
    matches = code_query.matches(node)

    matches.map do |match|
      line_node = match.captures.first.node
      source[line_node.start_byte...line_node.end_byte]
    end.join("\n")
  end

  def extract_expectations(nodes, source)
    nodes.map do |node|
      text = source[node.start_byte...node.end_byte]
      # Clean up expectation format (#=> result)
      text.gsub(/^#\s*=>\s*/, '').strip
    end
  end
end

# Usage example:
if __FILE__ == $0
  root_dir = Pathname.new(__dir__)
  language_path = root_dir.join('build/Release/tree_sitter_ruby_tryouts.dylib')

  parser = TryoutParser.new(language_path)
  test_file = parser.parse_file(root_dir.join('../try/step1_try.rb'))

  puts "File: #{test_file.path}"
  test_file.test_cases.each do |test|
    puts "\nTest: #{test.title}"
    puts "Code:\n#{test.code}"
    puts "Expectations:"
    test.expectations.each { |exp| puts "- #{exp}" }
    puts "-" * 40
  end
end
