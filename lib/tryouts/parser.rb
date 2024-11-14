#require "tree_sitter"

require 'tree_stand'
require 'fileutils'
require 'pathname'

TreeStand.configure do
  language_path = BASE_PATH.join('lib/tryouts')
  config.parser_path = language_path
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
  attr_reader :tree, :parser, :root, :cursor

  def initialize(path)
    @parser = TreeStand::Parser.new("tryouts")
    @tree = parse_file(path)
    @root = tree.root_node
    @cursor = tree.query(QUERY_TEXT)
  end

  def parse_file(path)
    source_code = File.read(path)
    @parser.parse_string(source_code) # returns a TreeStand::Tree
  end

  def run

  end

  def report

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
