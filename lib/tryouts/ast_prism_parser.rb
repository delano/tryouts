require 'prism'
require_relative 'ast_helpers'
require_relative 'test_case'

class Tryouts
  # AST-based parser using Prism's visitor pattern
  # Learning-focused implementation that addresses HEREDOC and comment placement issues
  class AstPrismParser < Prism::Visitor
    def initialize(source_path)
      @source_path = source_path
      @source = File.read(source_path)
      @prism_result = Prism.parse(@source)

      # Collected during AST traversal
      @top_level_statements = []
      @string_literals = []
      @executable_code = []
      @structural_context = {}

      # For learning and debugging
      @debug_info = {
        nodes_visited: 0,
        string_nodes_found: 0,
        heredocs_found: 0,
        potential_test_patterns_in_strings: 0
      }
    end

    def parse
      return handle_syntax_errors if @prism_result.failure?

      # Phase 1: AST traversal to collect structural information
      visit(@prism_result.value)

      # Phase 2: Use structural information for intelligent classification
      classified_statements = classify_statements_with_context

      # Phase 3: Group into test cases using structural understanding
      test_blocks = group_statements_into_test_blocks(classified_statements)

      # Phase 4: Build domain objects
      build_testrun(test_blocks)
    end

    # Learning method: expose debug information for team exploration
    def debug_info
      @debug_info
    end

    # Learning method: show what AST parsing discovered vs line-based parsing
    def structural_insights
      {
        total_statements: @top_level_statements.size,
        string_literals: @string_literals.map { |s|
          {
            type: s[:type],
            line: s[:node].location.start_line,
            contains_test_patterns: s[:contains_test_patterns]
          }
        },
        executable_statements: @executable_code.size,
        comments_by_context: analyze_comment_context
      }
    end

    # ========== AST Visitor Methods (must be public for Prism) ==========

    def visit_program_node(node)
      @debug_info[:nodes_visited] += 1

      # Extract top-level statements for test analysis
      @top_level_statements = ASTHelpers.top_level_statements(node)

      super
    end

    def visit_string_node(node)
      @debug_info[:nodes_visited] += 1
      @debug_info[:string_nodes_found] += 1

      content = ASTHelpers.extract_string_content(node, @source)
      contains_test_patterns = ASTHelpers.contains_test_like_patterns?(content)

      if contains_test_patterns
        @debug_info[:potential_test_patterns_in_strings] += 1
      end

      @string_literals << {
        node: node,
        type: :string,
        content: content,
        contains_test_patterns: contains_test_patterns
      }

      super
    end

    def visit_interpolated_string_node(node)
      @debug_info[:nodes_visited] += 1
      @debug_info[:string_nodes_found] += 1

      is_heredoc = ASTHelpers.heredoc?(node)
      if is_heredoc
        @debug_info[:heredocs_found] += 1
      end

      content = ASTHelpers.extract_string_content(node, @source)
      contains_test_patterns = ASTHelpers.contains_test_like_patterns?(content)

      if contains_test_patterns
        @debug_info[:potential_test_patterns_in_strings] += 1

        # This is the key learning insight: AST parsing elegantly handles this case
        # We KNOW this is string content, not executable test code
        log_heredoc_insight(node, content)
      end

      @string_literals << {
        node: node,
        type: is_heredoc ? :heredoc : :interpolated_string,
        content: content,
        contains_test_patterns: contains_test_patterns
      }

      super
    end

    def visit_call_node(node)
      @debug_info[:nodes_visited] += 1

      # This is executable code that could have associated expectations
      @executable_code << {
        node: node,
        type: :method_call,
        line: node.location.start_line
      }

      super
    end

    def visit_local_variable_write_node(node)
      @debug_info[:nodes_visited] += 1

      # Variable assignments are potential test code
      @executable_code << {
        node: node,
        type: :assignment,
        line: node.location.start_line
      }

      super
    end

    private

    # ========== Classification Methods ==========

    def classify_statements_with_context
      comments = @prism_result.comments

      @top_level_statements.map.with_index do |statement, index|
        # Use AST structure for intelligent classification
        role = ASTHelpers.classify_statement_role(
          statement,
          comments,
          index,
          @top_level_statements.size
        )

        node_comments = ASTHelpers.comments_for_node(comments, statement)

        {
          node: statement,
          role: role,
          line: statement.location.start_line,
          comments: node_comments,
          is_string_literal: ASTHelpers.string_literal?(statement),
          code_content: ASTHelpers.extract_code_content(statement, @source)
        }
      end
    end

    def group_statements_into_test_blocks(classified_statements)
      blocks = []
      current_block = nil

      classified_statements.each do |stmt|
        case stmt[:role]
        when :test_with_description, :test_without_description
          # Start new test block
          blocks << current_block if current_block
          current_block = {
            type: :test,
            description: extract_description_from_comments(stmt[:comments][:preceding]),
            statements: [stmt],
            expectations: extract_expectations_from_comments(stmt[:comments][:following]),
            line_range: stmt[:line]..stmt[:line]
          }

        when :code_statement
          # Add to current block or create setup/teardown
          if current_block
            current_block[:statements] << stmt
            current_block[:line_range] = current_block[:line_range].first..stmt[:line]
          else
            # Could be setup code
            blocks << {
              type: :setup,
              statements: [stmt],
              line_range: stmt[:line]..stmt[:line]
            }
          end

        when :potential_setup
          blocks << {
            type: :setup,
            statements: [stmt],
            line_range: stmt[:line]..stmt[:line]
          }

        when :potential_teardown
          blocks << current_block if current_block
          current_block = nil
          blocks << {
            type: :teardown,
            statements: [stmt],
            line_range: stmt[:line]..stmt[:line]
          }
        end
      end

      blocks << current_block if current_block
      blocks.compact
    end

    # ========== Helper Methods ==========

    def extract_description_from_comments(comments)
      description_comments = comments.select do |comment|
        ASTHelpers.test_description_comment?(comment.slice)
      end

      return '' if description_comments.empty?

      # Combine multiple description comments
      description_comments
        .map { |c| c.slice.gsub(/^#\s*/, '').gsub(/^##\s*/, '').strip }
        .join(' ')
        .strip
    end

    def extract_expectations_from_comments(comments)
      comments.filter_map do |comment|
        next unless ASTHelpers.expectation_comment?(comment.slice)

        content = comment.slice.gsub(/^#\s*/, '').strip
        type = determine_expectation_type(content)

        {
          content: content.gsub(/^=.?>\s*/, ''),
          type: type,
          line: comment.location.start_line
        }
      end
    end

    def determine_expectation_type(content)
      case content
      when /^=!>/ then :exception
      when /^=<>/ then :intentional_failure
      when /^==>/ then :true
      when /^=\/=>/ then :false
      when /^=\|>/ then :boolean
      when /^=:>/ then :result_type
      when /^=~>/ then :regex_match
      when /^=%>/ then :performance_time
      when /^=\d+>/ then :output
      else :regular
      end
    end

    def build_testrun(test_blocks)
      setup_blocks = test_blocks.select { |b| b[:type] == :setup }
      test_blocks = test_blocks.select { |b| b[:type] == :test }
      teardown_blocks = test_blocks.select { |b| b[:type] == :teardown }

      Testrun.new(
        setup: build_setup(setup_blocks),
        test_cases: test_blocks.map { |block| build_test_case(block) },
        teardown: build_teardown(teardown_blocks),
        source_file: @source_path,
        metadata: {
          parsed_at: Time.now,
          parser: :ast_prism_v1,
          debug_info: @debug_info
        }
      )
    end

    def build_setup(setup_blocks)
      return Setup.new(code: '', line_range: 0..0, path: @source_path) if setup_blocks.empty?

      code = setup_blocks.flat_map { |block|
        block[:statements].filter_map { |stmt| stmt[:code_content] }
      }.join("\n")

      line_range = calculate_blocks_range(setup_blocks)

      Setup.new(code: code, line_range: line_range, path: @source_path)
    end

    def build_teardown(teardown_blocks)
      return Teardown.new(code: '', line_range: 0..0, path: @source_path) if teardown_blocks.empty?

      code = teardown_blocks.flat_map { |block|
        block[:statements].filter_map { |stmt| stmt[:code_content] }
      }.join("\n")

      line_range = calculate_blocks_range(teardown_blocks)

      Teardown.new(code: code, line_range: line_range, path: @source_path)
    end

    def build_test_case(block)
      code = block[:statements].filter_map { |stmt| stmt[:code_content] }.join("\n")

      expectations = block[:expectations].map do |exp|
        Expectation.new(content: exp[:content], type: exp[:type])
      end

      source_lines = @source.lines[block[:line_range]].map(&:chomp)
      first_expectation_line = block[:expectations].first&.dig(:line) || block[:line_range].first

      TestCase.new(
        description: block[:description],
        code: code,
        expectations: expectations,
        line_range: block[:line_range],
        path: @source_path,
        source_lines: source_lines,
        first_expectation_line: first_expectation_line
      )
    end

    def calculate_blocks_range(blocks)
      return 0..0 if blocks.empty?

      all_ranges = blocks.map { |b| b[:line_range] }
      all_ranges.first.first..all_ranges.last.last
    end

    def log_heredoc_insight(node, content)
      # Learning insight logging for team understanding
      puts "🔍 AST Learning Insight: HEREDOC at line #{node.location.start_line}"
      puts "   Contains test-like patterns, but AST knows it's string content!"
      puts "   Line-based parsing would incorrectly classify this as executable test code."
    end

    def analyze_comment_context
      comments = @prism_result.comments

      {
        total: comments.size,
        expectation_comments: comments.count { |c| ASTHelpers.expectation_comment?(c.slice) },
        description_comments: comments.count { |c| ASTHelpers.test_description_comment?(c.slice) },
        regular_comments: comments.count { |c|
          !ASTHelpers.expectation_comment?(c.slice) &&
          !ASTHelpers.test_description_comment?(c.slice)
        }
      }
    end

    def handle_syntax_errors
      errors = @prism_result.errors.map do |error|
        line_context = @source.lines[error.location.start_line - 1] || ''

        TryoutSyntaxError.new(
          error.message,
          line_number: error.location.start_line,
          context: line_context,
          source_file: @source_path
        )
      end

      raise errors.first if errors.any?
    end
  end
end
