/**
 * @file Tryouts grammar for tree-sitter
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'ruby_tryouts',

  extras: $ => [/\s/],

  conflicts: $ => [
    [$.code_block, $.source_file]
  ],

  precedences: $ => [
    ['test_case'],
    ['code_block'],
    ['code_line']
  ],

  rules: {
    source_file: $ => repeat(choice(
      $.test_case,
      $.code_line,
      $.comment
    )),

    test_case: $ => prec('test_case', seq(
      $.code_block,
      $.expectation
    )),

    code_block: $ => prec('code_block', repeat1(
      choice(
        $.code_line,
        $.comment
      )
    )),

    code_line: $ => prec('code_line',
      /[^#\n][^\n]*/
    ),

    comment: $ => choice(
      seq('#', /[^=>\n].*/),
      seq('##', /[^\n]*/)
    ),

    expectation: $ => seq(
      choice('#=>', '# =>'),
      field('value', /[^\n]*/)
    ),

    word: $ => /\w+/,
    _whitespace: $ => /\s+/
  }
});
