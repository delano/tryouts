# lib/tryouts/parsers/shared_methods.rb

require_relative '../parser_warning'

class Tryouts
  module Parsers
    module SharedMethods
      # Check if a description token at given index is followed by actual test content
      # (code + expectations), indicating it's a real test case vs just a comment
      def has_following_test_pattern?(tokens, desc_index)
        return false if desc_index >= tokens.length - 1

        # Look ahead for code and expectation tokens after this description
        has_code        = false
        has_expectation = false

        (desc_index + 1...tokens.length).each do |i|
          token = tokens[i]

          case token[:type]
          when :code
            has_code = true
          when :description
            # If we hit another description before finding expectations,
            # this description doesn't have a complete test pattern
            break
          else
            if is_expectation_type?(token[:type])
              has_expectation = true
              break if has_code # Found both code and expectation
            end
          end
        end

        has_code && has_expectation
      end

      def group_into_test_blocks(tokens)
        blocks        = []
        current_block = new_test_block

        tokens.each_with_index do |token, index|
          case [current_block, token]
          in [_, { type: :description, content: String => desc, line: Integer => line_num }]
            # Only combine descriptions if current block has a description but no code/expectations yet
            # Allow blank lines between multi-line descriptions
            if !current_block[:description].empty? && current_block[:code].empty? && current_block[:expectations].empty?
              # Multi-line description continuation
              current_block[:description] = [current_block[:description], desc].join(' ').strip
            elsif has_following_test_pattern?(tokens, index)
              # Only create new block if description is followed by actual test pattern
              blocks << current_block if block_has_content?(current_block)
              current_block = new_test_block.merge(description: desc, start_line: line_num)
            else
              # Treat as regular comment - don't create new block
              current_block[:comments] << token
            end

          in [{ expectations: [], start_line: nil }, { type: :code, content: String => code, line: Integer => line_num }]
            # First code in a new block - set start_line
            current_block[:code] << token
            current_block[:start_line] = line_num

          in [{ expectations: [] }, { type: :code, content: String => code }]
            # Code before expectations - add to current block
            current_block[:code] << token

          in [{ expectations: Array => exps }, { type: :code }] if !exps.empty?
            # Code after expectations - finalize current block and start new one
            blocks << current_block
            current_block = new_test_block.merge(code: [token], start_line: token[:line])

          in [_, { type: :expectation }]
            current_block[:expectations] << token

          in [_, { type: :exception_expectation }]
            current_block[:expectations] << token

          in [_, { type: :intentional_failure_expectation }]
            current_block[:expectations] << token

          in [_, { type: :true_expectation }]
            current_block[:expectations] << token

          in [_, { type: :false_expectation }]
            current_block[:expectations] << token

          in [_, { type: :boolean_expectation }]
            current_block[:expectations] << token

          in [_, { type: :non_nil_expectation }]
            current_block[:expectations] << token

          in [_, { type: :result_type_expectation }]
            current_block[:expectations] << token

          in [_, { type: :regex_match_expectation }]
            current_block[:expectations] << token

          in [_, { type: :performance_time_expectation }]
            current_block[:expectations] << token

          in [_, { type: :output_expectation }]
            current_block[:expectations] << token

          in [_, { type: :comment | :blank }]
            add_context_to_block(current_block, token)
          end
        end

        blocks << current_block if block_has_content?(current_block)
        classify_blocks(blocks)
      end

      # Find where a test case ends by looking for the last expectation
      # before the next test description or end of tokens
      def find_test_case_end(tokens, start_index)
        last_expectation_line = nil

        # Look forward from the description for expectations
        (start_index + 1).upto(tokens.length - 1) do |i|
          token = tokens[i]

          # Stop if we hit another test description
          break if token[:type] == :description

          # Track the last expectation we see
          if is_expectation_type?(token[:type])
            last_expectation_line = token[:line]
          end
        end

        last_expectation_line
      end

      # Find actual test case boundaries by looking for ## descriptions or # TEST: patterns
      # followed by code and expectations
      def find_test_case_boundaries(tokens)
        boundaries = []

        tokens.each_with_index do |token, index|
          if token[:type] == :description
            start_line = token[:line]
            end_line   = find_test_case_end(tokens, index)
            boundaries << { start: start_line, end: end_line } if end_line
          end
        end

        boundaries
      end

      # Convert potential_descriptions to descriptions or comments using test case boundaries
      def classify_potential_descriptions_with_boundaries(tokens, test_boundaries)
        tokens.map.with_index do |token, index|
          if token[:type] == :potential_description
            line_num         = token[:line]
            within_test_case = test_boundaries.any? do |boundary|
              line_num >= boundary[:start] && line_num <= boundary[:end]
            end

            if within_test_case
              token.merge(type: :comment)
            else
              content = token[:content].strip

              looks_like_test_description = content.match?(/test|example|demonstrate|show|should|when|given/i) &&
                                            content.length > 10

              prev_token      = index > 0 ? tokens[index - 1] : nil
              has_code_before = prev_token && prev_token[:type] == :code

              if has_code_before || !looks_like_test_description
                token.merge(type: :comment)
              else
                following_tokens     = tokens[(index + 1)..]
                meaningful_following = following_tokens.reject { |t| [:blank, :comment].include?(t[:type]) }
                test_window          = meaningful_following.first(5)
                has_code             = test_window.any? { |t| t[:type] == :code }
                has_expectation      = test_window.any? { |t| is_expectation_type?(t[:type]) }

                if has_code && has_expectation && looks_like_test_description
                  token.merge(type: :description)
                else
                  token.merge(type: :comment)
                end
              end
            end
          else
            token
          end
        end
      end

      # Check if token type represents any kind of expectation
      def is_expectation_type?(type)
        [
          :expectation, :exception_expectation, :intentional_failure_expectation,
          :true_expectation, :false_expectation, :boolean_expectation,
          :result_type_expectation, :regex_match_expectation,
          :performance_time_expectation, :output_expectation, :non_nil_expectation
        ].include?(type)
      end

      # Process classified test blocks into domain objects
      def process_test_blocks(classified_blocks)
        setup_blocks    = classified_blocks.filter { |block| block[:type] == :setup }
        test_blocks     = classified_blocks.filter { |block| block[:type] == :test }
        teardown_blocks = classified_blocks.filter { |block| block[:type] == :teardown }

        testrun = Testrun.new(
          setup: build_setup(setup_blocks),
          test_cases: test_blocks.map { |block| build_test_case(block) },
          teardown: build_teardown(teardown_blocks),
          source_file: @source_path,
          metadata: { parsed_at: @parsed_at, parser: parser_type },
          warnings: warnings
        )

        # Validate strict mode after collecting all warnings
        validate_strict_mode(testrun)

        testrun
      end

      def build_setup(setup_blocks)
        return Setup.new(code: '', line_range: 0..0, path: @source_path) if setup_blocks.empty?

        Setup.new(
          code: extract_pure_code_from_blocks(setup_blocks),
          line_range: calculate_block_range(setup_blocks),
          path: @source_path,
        )
      end

      def build_teardown(teardown_blocks)
        return Teardown.new(code: '', line_range: 0..0, path: @source_path) if teardown_blocks.empty?

        Teardown.new(
          code: extract_pure_code_from_blocks(teardown_blocks),
          line_range: calculate_block_range(teardown_blocks),
          path: @source_path,
        )
      end

      # Modern Ruby 3.4+ pattern matching for robust code extraction
      def extract_pure_code_from_blocks(blocks)
        blocks
          .flat_map { |block| block[:code] }
          .filter_map do |token|
            case token
            in { type: :code, content: String => content }
              content
            else
              nil
            end
          end
          .join("\n")
      end

      def calculate_block_range(blocks)
        return 0..0 if blocks.empty?

        valid_blocks = blocks.filter { |block| block[:start_line] && block[:end_line] }
        return 0..0 if valid_blocks.empty?

        line_ranges = valid_blocks.map { |block| block[:start_line]..block[:end_line] }
        line_ranges.first.first..line_ranges.last.last
      end

      def extract_code_content(code_tokens)
        code_tokens
          .filter_map do |token|
            case token
            in { type: :code, content: String => content }
              content
            else
              nil
            end
          end
          .join("\n")
      end

      def parse_ruby_line(line)
        return nil if line.strip.empty?

        result = Prism.parse(line.strip)
        case result
        in { errors: [] => errors, value: { body: { body: [ast] } } }
          ast
        in { errors: Array => errors } if errors.any?
          { type: :parse_error, errors: errors, raw: line }
        else
          nil
        end
      end

      def parse_expectation(expr)
        parse_ruby_line(expr)
      end

      def new_test_block
        {
          description: '',
          code: [],
          expectations: [],
          comments: [],
          start_line: nil,
          end_line: nil,
        }
      end

      def block_has_content?(block)
        case block
        in { description: String => desc, code: Array => code, expectations: Array => exps }
          !desc.empty? || !code.empty? || !exps.empty?
        else
          false
        end
      end

      def add_context_to_block(block, token)
        case [block[:expectations].empty?, token]
        in [true, { type: :comment | :blank }]
          block[:code] << token
        in [false, { type: :comment | :blank }]
          block[:comments] << token
        end
      end

      # Classify blocks as setup, test, or teardown based on content
      def classify_blocks(blocks)
        blocks.map.with_index do |block, index|
          block_type = case block
                       in { expectations: [] } if index == 0
                         :setup
                       in { expectations: [] } if index == blocks.size - 1
                         :teardown
                       in { expectations: Array => exps } if !exps.empty?
                         :test
                       else
                         :preamble
                       end

          block.merge(type: block_type, end_line: calculate_end_line(block))
        end
      end

      def calculate_end_line(block)
        content_tokens = [*block[:code], *block[:expectations]]
        return block[:start_line] if content_tokens.empty?

        content_tokens.map { |token| token[:line] }.max || block[:start_line]
      end

      def build_test_case(block)
        case block
        in {
          type: :test,
          description: String => desc,
          code: Array => code_tokens,
          expectations: Array => exp_tokens,
          start_line: Integer => start_line,
          end_line: Integer => end_line
        }
          # Collect warning for unnamed test
          collect_unnamed_test_warning(block)

          source_lines           = @lines[start_line..end_line]
          first_expectation_line = exp_tokens.empty? ? start_line : exp_tokens.first[:line]

          TestCase.new(
            description: desc,
            code: extract_code_content(code_tokens),
            expectations: exp_tokens.map do |token|
              type = case token[:type]
                     when :exception_expectation then :exception
                     when :intentional_failure_expectation then :intentional_failure
                     when :true_expectation then :true # rubocop:disable Lint/BooleanSymbol
                     when :false_expectation then :false # rubocop:disable Lint/BooleanSymbol
                     when :boolean_expectation then :boolean
                     when :result_type_expectation then :result_type
                     when :regex_match_expectation then :regex_match
                     when :performance_time_expectation then :performance_time
                     when :output_expectation then :output
                     when :non_nil_expectation then :non_nil
                     else :regular
                     end

              if token[:type] == :output_expectation
                OutputExpectation.new(content: token[:content], type: type, pipe: token[:pipe])
              else
                Expectation.new(content: token[:content], type: type)
              end
            end,
            line_range: start_line..end_line,
            path: @source_path,
            source_lines: source_lines,
            first_expectation_line: first_expectation_line,
          )
        else
          raise "Invalid test block structure: #{block}"
        end
      end

      def handle_syntax_errors
        errors = @prism_result.errors.map do |error|
          line_context = @lines[error.location.start_line - 1] || ''

          TryoutSyntaxError.new(
            error.message,
            line_number: error.location.start_line,
            context: line_context,
            source_file: @source_path,
          )
        end

        raise errors.first if errors.any?
      end

      # Parser type identification for metadata - to be overridden by subclasses
      def parser_type
        :shared
      end

      # Warning collection methods
      def add_warning(warning)
        @warnings ||= []
        @warnings << warning
      end

      def warnings
        @warnings ||= []
      end

      def collect_unnamed_test_warning(block)
        return unless block[:type] == :test && block[:description].empty?

        line_number = block[:start_line] + 1
        context = @lines[block[:start_line]] || ''

        add_warning(ParserWarning.unnamed_test(
          line_number: line_number,
          context: context.strip
        ))
      end

      def validate_strict_mode(testrun)
        return unless @options[:strict]

        unnamed_test_warnings = warnings.select { |w| w.type == :unnamed_test }
        return if unnamed_test_warnings.empty?

        # In strict mode, fail with first unnamed test error
        first_warning = unnamed_test_warnings.first
        raise TryoutSyntaxError.new(
          "Strict mode: #{first_warning.message} at line #{first_warning.line_number}. #{first_warning.suggestion}",
          line_number: first_warning.line_number,
          context: first_warning.context,
          source_file: @source_path
        )
      end

    end
  end
end
