# lib/tryouts/parsers/shared_methods.rb

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

    end
  end
end
