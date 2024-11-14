#require "tree_sitter"

require 'tree_stand'
require 'fileutils'
require 'pathname'
#
TreeStand.configure do
  language_path = BASE_PATH.join('lib/tryouts')
  config.parser_path = language_path
end

module TreeSitter
  def assert_eq(a, b)
    puts "#{a} #{a == b ? '==' : '!='} #{b}"
  end

  def section
    puts '-' * 79
  end
end

QUERY_TEXT = <<~QUERY
(source_file
  (setup_section
    (non_description_line)*)? @setup

  (testcase
    (description_line) @test.description
    (code_line)* @test.code
    (expectation_line) @test.expectation)* @test

  (teardown_section
    (non_description_line)*)? @teardown)
QUERY

class Tryouts::Parser
  def initialize(language_path)
#    @language = TreeSitter::Language.load('tryouts', language_path)
#    @parser = TreeSitter::Parser.new
#    @parser.language = @language
#
#    @query = TreeSitter::Query.new(@language, QUERY_TEXT)

    @parser = TreeStand::Parser.new("tryouts")


  end

  def parse_file(path)
    source_code = File.read(path)
    tree = @parser.parse_string(source_code)
    root = tree.root_node

    cursor = tree.query(QUERY_TEXT)

          #require 'pry-byebug'; binding.pry;

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
