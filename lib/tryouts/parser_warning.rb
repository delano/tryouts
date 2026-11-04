# lib/tryouts/parser_warning.rb
#
# frozen_string_literal: true

class Tryouts
  # Something in a tryouts file that parsed but probably does not mean what
  # the author intended. line_number is 1-based.
  ParserWarning = Data.define(:type, :message, :line_number, :context, :suggestion) do
    # An expectation with no `##` description since the previous test. The
    # suggestion names the statement the expectation was attached to, because
    # that is the part a reader cannot see from the warning line alone.
    def self.unnamed_test(line_number:, context:, expectation_line: nil, subject_line: nil, statement_count: 1, spaced: false, swallows_prologue: false)
      suggestion = "Add a test description using '## Description' prefix"
      if expectation_line && subject_line
        span        = statement_count > 1 ? "lines #{line_number}-#{subject_line} (#{statement_count} statements)" : "line #{subject_line}"
        suggestion += ". The expectation at line #{expectation_line} asserts on the value of #{span}"
        suggestion += ', so this test has swallowed the whole prologue and the file has no setup' if swallows_prologue
      end
      if spaced
        suggestion += ". If line #{expectation_line} is prose rather than an expectation, drop the '=>'"
      end

      new(
        type: :unnamed_test,
        message: 'Test case without explicit description',
        line_number: line_number,
        context: context,
        suggestion: suggestion,
      )
    end

    def self.malformed_expectation(line_number:, syntax:, context:)
      new(
        type: :malformed_expectation,
        message: "Malformed expectation syntax '#{syntax}' at line #{line_number}",
        line_number: line_number,
        context: context,
        suggestion: 'Use valid expectation syntax like #=>, #==>, #=:>, #=!>, etc.',
      )
    end

    # `##=> 2` is an expectation behind a description marker. It is neither
    # a description nor an expectation, so it fails until it is rewritten.
    def self.doubled_hash_expectation(line_number:, syntax:, context:)
      new(
        type: :malformed_expectation,
        message: "Malformed expectation syntax '#{syntax}' at line #{line_number}",
        line_number: line_number,
        context: context,
        suggestion: "Expectations start with a single '#'. Write '#=>' to assert, or '# #=>' to comment the expectation out",
      )
    end

    # `#==> true` evaluates the literal `true`, not the result. It always passes.
    def self.vacuous_expectation(line_number:, context:)
      new(
        type: :vacuous_expectation,
        message: "Expectation at line #{line_number} tests a literal, not the result",
        line_number: line_number,
        context: context,
        suggestion: "#==>, #=/=> and #=|> evaluate the expression after the arrow. Write '#=> true' to compare the result, or '#==> result' to require it to be true",
      )
    end

    def self.ignored_expectation_text(line_number:, context:)
      new(
        type: :ignored_expectation_text,
        message: "Text after #=*> at line #{line_number} is ignored",
        line_number: line_number,
        context: context,
        suggestion: "#=*> only checks that the result is not nil. Use '#==> expression' to assert something more",
      )
    end

    # An expectation-shaped comment inside a method, block, class or literal.
    # It is part of that statement's body, so nothing evaluates it.
    def self.nested_expectation(line_number:, context:)
      new(
        type: :nested_expectation,
        message: "Expectation at line #{line_number} is inside a statement and will not be evaluated",
        line_number: line_number,
        context: context,
        suggestion: 'Expectations apply to top-level statements. Move it below the end of the enclosing statement',
      )
    end

    # A `##` description with code below it but no expectation before the
    # next description, so no test has that name. Often an expectation with
    # a mistyped operator that reads as a plain comment (`#==`, `#=~ /x/`).
    def self.description_without_expectation(line_number:, description:, section:, context:)
      runs_as = { setup: 'setup', interlude: 'an interlude', teardown: 'teardown' }.fetch(section)
      new(
        type: :description_without_expectation,
        message: "Test '#{description}' at line #{line_number} has no expectation; its code runs as #{runs_as}",
        line_number: line_number,
        context: context,
        suggestion: "Add an expectation such as '#=> value' below the test's code, and check the operator of any comment meant as one (#=>, #==>, #=~>, #=1>, ...). Use a single '#' for a heading that is not a test",
      )
    end

    # An expectation with no statement above it in its own test: before the
    # first statement, or below a `##` description with no code in between.
    # It is not evaluated.
    def self.expectation_without_subject(line_number:, context:, description_line: nil)
      if description_line
        message    = "Expectation at line #{line_number} has no statement between it and the description at line #{description_line}"
        suggestion = "A '##' line starts a new test, so this expectation does not apply to the test above it. Add the code it should test below line #{description_line}, or move the expectation above the description"
      else
        message    = "Expectation at line #{line_number} has no statement above it"
        suggestion = 'An expectation asserts on the value of the statement above it. Add the code it should test'
      end

      new(
        type: :expectation_without_subject,
        message: message,
        line_number: line_number,
        context: context,
        suggestion: suggestion,
      )
    end
  end
end
