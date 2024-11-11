/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'tryouts',

  rules: {
    source_file: $ => seq(
      optional($.setup_section),
      repeat1($.tryout_block),
      optional($.teardown_section)
    ),

    setup_section: $ => seq(
      repeat($.comment),
      repeat($.require_statement),
      repeat1(choice(
        $.assignment_statement,
        $.configuration_statement,
        $.any_statement
      ))
    ),

    teardown_section: $ => repeat1($.any_statement),

    tryout_block: $ => seq(
      repeat1($.tryout_description),
      repeat($.code_line),
      $.expectation
    ),

    tryout_description: $ => seq(
      '##',
      /[^\n]+/
    ),

    expectation: $ => seq(
      '#=>',
      /[^\n]+/
    ),

    comment: $ => seq(
      '#',
      /[^\n]*/
    ),

    require_statement: $ => seq(
      'require',
      $.string_literal
    ),

    assignment_statement: $ => seq(
      '@',
      /[a-zA-Z_][a-zA-Z0-9_]*/,
      '=',
      $.any_value
    ),

    configuration_statement: $ => seq(
      /[A-Z][a-zA-Z0-9:]*\.(configure|boot|path)/,
      /[^\n]+/
    ),

    code_line: $ => /[^#][^\n]*/,

    string_literal: $ => choice(
      seq("'", /[^']*/, "'"),
      seq('"', /[^"]*/, '"')
    ),

    any_value: $ => /[^\n]+/,

    any_statement: $ => /[^\n]+/
  }
});
