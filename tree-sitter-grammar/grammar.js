// grammar.js
module.exports = grammar({
  name: 'tryouts',

  rules: {
    // The starting rule
    source_file: $ => repeat($.testcase),

    // Definition of a testcase
    testcase: $ => seq(
      repeat1($.description_line),
      repeat($.code_line),
      repeat1($.expectation_line),
      // Allowing for optional blank lines at the end of a testcase
      repeat($.blank_line)
    ),

    // Descriptions start with '##'
    description_line: $ => seq('##', /[^\n]*/, '\n'),

    // Code lines:
    // - Lines starting with '#' but not followed by '#' or '=>'
    // - Lines starting with any character except '#'
    code_line: $ => choice(
      seq('#', /[^#=>][^\n]*/, '\n'),
      seq(/[^#\n][^\n]*/, '\n')
    ),

    // Expectations start with '#=>'
    expectation_line: $ => seq('#=>', /[^\n]*/, '\n'),

    // Blank lines (used as separators)
    blank_line: $ => /\s*\n/,
  }
});
