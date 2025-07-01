// grammar.js
module.exports = grammar({
  name: 'tryouts',

  rules: {
    // The starting rule
    source_file: $ => seq(
      optional($.setup_section),
      repeat1($.testcase),
      optional($.teardown_section)
    ),

    // Setup section: lines before the first testcase
    setup_section: $ => repeat1($.non_description_line),

    // Teardown section: lines after the last testcase
    teardown_section: $ => repeat1($.non_description_line),

    // Definition of a testcase
    testcase: $ => seq(
      field("description", repeat1($.description_line)),
      field("testcode", repeat($.code_line)),
      field("expectations", repeat1($.expectation_line))
      // Allow for blank lines within and after a testcase
      //optional($.blank_line)
    ),

    // Descriptions start with '##'
    description_line: $ => seq('##', /[^\n]*/, '\n'),

    // Code lines:
    // - Lines starting with '#' but not '#' or '##' or '#=>'
    // - Lines starting with any character except '#'
    code_line: $ => choice(
      seq('#', /[^#=>\n][^\n]*/, '\n'),
      seq(/[^#\n][^\n]*/, '\n')
    ),

    // Expectations start with '#=>'
    expectation_line: $ => seq('#=>', /[^\n]*/, '\n'),

    // Blank lines (used within and between testcases)
    blank_line: $ => /\s*\n/,

    // Non-description lines (for setup and teardown sections)
    non_description_line: $ => choice(
      // Lines starting with any character except '#'
      seq(/[^#\n][^\n]*/, '\n'),
      // Lines starting with '#' but not followed by '#'
      seq('#', /[^#\n][^\n]*/, '\n')
    ),
  }
});
