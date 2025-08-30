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
  end
end
