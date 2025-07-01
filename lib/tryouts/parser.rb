require "tree_stand"
require "fileutils"
require "pathname"
require_relative "models"

TreeStand.configure do
  language_path = BASE_PATH.join('./tree-sitter-tryouts/')
  config.parser_path = language_path
end

QUERY_TEXT = <<~QUERY

(testcase
(description_line)+ @test.description
(testcode)+ @test.code
(expectation_line)+ @test.expectation)+ @test


QUERY

class Tryouts::Parser
  attr_reader :tree, :parser, :root, :cursor, :source_code, :testrun, :results, :setup_error, :captured_hashes

  class TestResult
    attr_reader :test_case, :result, :error, :output

    def initialize(test_case, result: nil, error: nil, output: nil)
      @test_case = test_case
      @result = result
      @error = error
      @output = output
    end

    def success?
      !error && (test_case.expectations.nil? || test_case.expectations.empty? ||
                test_case.expectations.all? { |exp| exp == result.to_s })
    end
  end

  def initialize(path)
    @parser = TreeStand::Parser.new("tryouts")
    @source_code = File.read(path)
    @tree = parse_file(path)
    #@root = tree.root_node
    #@tree.walk do |node|
    #  p [node.type, node.text]
    #end
    @tstree = tree.ts_tree
    @root = @tstree.root_node
    #@captured_hashes = tree.query(QUERY_TEXT)
    #pp @cursor.length
    #@testrun = parse
  end

  def parse_file(path)
    puts path
    @parser.parse_string(source_code) # returns a TreeStand::Tree
  end

  def parse
    p @root.fields
    @root.each_named do |child,x|
      p [child.class, x]
#      p child.fetch('description[').class
#
#      p child.type, child.text]
    end
    #puts '%d %s' % [@captured_hashes.length, @captured_hashes[0].keys]
    #captured_hashes.each_with_index do |hash, index|
    #  puts hash['test.description'].text
    #  puts hash['test.code'].text
    #  puts hash['test.expectation'].text
    #  #puts '%d %s' % [index, hash['test.description'].text]
    #  #puts '%d %s' % [index, hash['test.code'].text]
    #  #puts '%d %s' % [index, hash['test.expression']]
    #  puts hash['test']
    #end
#    setup = parse_setup
#    test_cases = parse_test_cases
#    teardown = parse_teardown
#
#    Tryouts::Testrun.new(
#      setup: setup,
#      test_cases: test_cases,
#      teardown: teardown
#    )
  end

  def run
    return
    context = create_execution_context
    @results = []

    begin
      # Run setup if present
      if testrun.setup && !testrun.setup.empty?
        context.class_eval(testrun.setup.code)
      end

      # Run each test case
      testrun.test_cases.each do |test_case|
        next if test_case.empty?

        begin
          output = StringIO.new
          original_stdout = $stdout
          $stdout = output

          result = context.class_eval(test_case.code)
          @results << TestResult.new(test_case, result: result, output: output.string)
        rescue => e
          @results << TestResult.new(test_case, error: e, output: output.string)
        ensure
          $stdout = original_stdout
        end
      end

      # Run teardown if present
      if testrun.teardown && !testrun.teardown.empty?
        context.class_eval(testrun.teardown.code)
      end
    rescue => e
      # Handle setup/teardown errors
      @setup_error = e
    end

    self
  end

  def report
    return "Setup failed: #{setup_error}" if setup_error

    total = results.size
    passed = results.count(&:success?)
    failed = total - passed

    output = []
    output << "\nTest Results:"
    output << "============="
    output << "Total: #{total}"
    output << "Passed: #{passed}"
    output << "Failed: #{failed}"
    output << "\nDetails:"
    output << "--------"

    results.each_with_index do |result, index|
      output << "\n#{index + 1}) #{result.test_case.description}"
      if result.success?
        output << "  ✓ PASS"
      else
        output << "  ✗ FAIL"
        if result.error
          output << "  Error: #{result.error.class}: #{result.error.message}"
          output << "  Backtrace:"
          output << result.error.backtrace.take(3).map { |line| "    #{line}" }
        else
          output << "  Expected: #{result.test_case.expectations.join(', ')}"
          output << "  Got: #{result.result}"
        end
      end
      unless result.output.to_s.empty?
        output << "  Output:"
        output << result.output.to_s.split("\n").map { |line| "    #{line}" }
      end
    end

    output.flatten.join("\n")
  end

  private

  def create_execution_context
    Class.new do
      # This provides an isolated namespace for each test run
      def self.tryouts_eval(&block)
        class_eval(&block)
      end
    end
  end

  def parse_setup
    setup_match = cursor.matches.find { |m| m.captures.key?("setup") }
    return nil unless setup_match

    setup_node = setup_match.captures["setup"].first
    return nil unless setup_node

    lines = extract_lines(setup_node)
    return nil if lines.empty?

    Tryouts::Setup.new(lines)
  end

  def parse_teardown
    teardown_match = cursor.matches.find { |m| m.captures.key?("teardown") }
    return nil unless teardown_match

    teardown_node = teardown_match.captures["teardown"].first
    return nil unless teardown_node

    lines = extract_lines(teardown_node)
    return nil if lines.empty?

    Tryouts::Teardown.new(lines)
  end

  def parse_test_cases
    test_matches = cursor.matches.select { |m| m.captures.key?("test") }

    test_matches.map do |match|
      description_node = match.captures["test.description"]&.first
      code_nodes = match.captures["test.code"]
      expectation_nodes = match.captures["test.expectation"]

      description = description_node ? [extract_text(description_node)] : []
      code = code_nodes ? code_nodes.map { |node| extract_text(node) } : []
      expectations = expectation_nodes ? expectation_nodes.map { |node| extract_expectation(node) } : []

      Tryouts::TestCase.new(
        description: description,
        code: code,
        expectations: expectations
      )
    end
  end

  def extract_lines(node)
    return [] unless node
    node.named_children.map { |child| extract_text(child) }
  end

  def extract_text(node)
    source_code[node.start_byte...node.end_byte].strip
  end

  def extract_expectation(node)
    text = source_code[node.start_byte...node.end_byte]
    text.gsub(/^#\s*=>\s*/, '').strip
  end
end
