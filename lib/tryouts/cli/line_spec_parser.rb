# lib/tryouts/cli/line_spec_parser.rb
#
# frozen_string_literal: true

class Tryouts
  class CLI
    class LineSpecParser
      # Parse a file path with optional line specification
      # Supports formats:
      #   - file.rb:19        (single line)
      #   - file.rb:19-45     (range)
      #   - file.rb:L19       (GitHub-style single line)
      #   - file.rb:L19-45    (GitHub-style range)
      #   - file.rb:L19-L45   (GitHub-style range with L on both)
      #
      # Returns [filepath, line_spec] where line_spec is nil or a Range/Integer
      def self.parse(path_with_spec)
        return [path_with_spec, nil] unless path_with_spec.include?(':')

        # Split on the last colon to handle paths with colons
        parts = path_with_spec.rpartition(':')
        filepath = parts[0]
        line_spec_str = parts[2]

        # If the filepath is empty, it means there was no colon or the input started with colon
        return [path_with_spec, nil] if filepath.empty?

        # If the "line spec" part looks like a Windows drive letter, this isn't a line spec
        return [path_with_spec, nil] if line_spec_str =~ /\A[a-zA-Z]\z/

        # Parse the line specification
        line_spec = parse_line_spec(line_spec_str)

        # If we couldn't parse it, treat the whole thing as a filepath
        return [path_with_spec, nil] if line_spec.nil?

        [filepath, line_spec]
      end

      private

      def self.parse_line_spec(spec)
        return nil if spec.nil? || spec.empty?

        # Remove 'L' prefix if present (GitHub style)
        spec = spec.gsub(/L/i, '')

        # Handle range (e.g., "19-80")
        if spec.include?('-')
          parts = spec.split('-', 2)

          # Validate that both parts are numeric
          return nil unless parts[0] =~ /\A\d+\z/ && parts[1] =~ /\A\d+\z/

          start_line = parts[0].to_i
          end_line = parts[1].to_i

          # Validate the numbers
          return nil if start_line <= 0 || end_line <= 0
          return nil if start_line > end_line

          start_line..end_line
        else
          # Single line number - validate it's numeric
          return nil unless spec =~ /\A\d+\z/

          line = spec.to_i
          return nil if line <= 0

          line
        end
      end

      # Check if a test case at the given line range matches the line specification
      # Test case line ranges are 0-based, user line specs are 1-based
      def self.matches?(test_case, line_spec)
        return true if line_spec.nil?

        # Convert user's 1-based line spec to 0-based for comparison
        zero_based_spec = case line_spec
        when Integer
          line_spec - 1
        when Range
          (line_spec.begin - 1)..(line_spec.end - 1)
        else
          line_spec
        end

        # Test case line_range is already 0-based
        test_range = test_case.line_range

        case zero_based_spec
        when Integer
          # Single line - check if it falls within the test's range
          test_range.cover?(zero_based_spec)
        when Range
          # Range - check if there's any overlap
          spec_start = zero_based_spec.begin
          spec_end = zero_based_spec.end
          test_start = test_range.begin
          test_end = test_range.end

          # Check for overlap: ranges overlap if start of one is before end of other
          !(test_end < spec_start || spec_end < test_start)
        else
          true
        end
      end
    end
  end
end
