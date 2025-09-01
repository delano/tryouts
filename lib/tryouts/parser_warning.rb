# lib/tryouts/parser_warning.rb

class Tryouts
  # Data structure for parser warnings
  ParserWarning = Data.define(:type, :message, :line_number, :context, :suggestion) do
    def self.unnamed_test(line_number:, context:)
      new(
        type: :unnamed_test,
        message: "Test case without explicit description",
        line_number: line_number,
        context: context,
        suggestion: "Add a test description using '## Description' prefix"
      )
    end

    def self.ambiguous_test_boundary(line_number:, context:)
      new(
        type: :ambiguous_boundary,
        message: "Ambiguous test case boundary detected",
        line_number: line_number,
        context: context,
        suggestion: "Use explicit '## Description' to clarify test structure"
      )
    end

    def self.malformed_expectation(line_number:, syntax:, context:)
      new(
        type: :malformed_expectation,
        message: "Malformed expectation syntax '#=#{syntax}>' at line #{line_number}",
        line_number: line_number,
        context: context,
        suggestion: "Use valid expectation syntax like #=>, #==>, #=:>, #=!>, etc."
      )
    end
  end
end
