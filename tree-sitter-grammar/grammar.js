module.exports = grammar({
  name: 'ruby_tryouts',

  extras: $ => [
    /[ \t]+/
  ],

  conflicts: $ => [
    //[$.test_case, $.code_line],
    //[$.source_file, $.test_case],
    [$.teardown_section, $.test_case],

  ],

  rules: {
    source_file: $ => seq(
      // Handle optional setup at start of file
      optional(prec.left($.setup_section)),

      // One or more test cases in the middle
      prec(1, repeat1($.test_case)),

      // Handle optional teardown at end of file
      //optional(prec.right($.teardown_section))
    ),

    setup_section: $ => prec.left(repeat1(
      choice(
        $.code_line,
        $.comment,
        //$.instance_var_declaration,
        $.blank_line
      )
    )),

    test_case: $ => seq(
      repeat1($.description),
      repeat1($.code_block_line),
      repeat1($.expectation),
      repeat1($.blank_line),
    ),

    teardown_section: $ => prec.right(seq(
      repeat1($.blank_line),
      repeat1(choice(
        $.code_line,
        $.comment,
        $.blank_line,
      )
    ))),

    code_block_line: $ => choice(
      $.code_line,
      $.comment,
      //$.instance_var_reference,
      $.blank_line,
    ),

    code_line: $ => seq(
      /[^#@\n][^\n]*/,
      $._newline
    ),

    expectation: $ => seq(
      choice('#=>', '# =>'),
      /[^\n]*/,
      $._newline
    ),

    description: $ => seq(
      '##',
      /[^\n]*/,
      $._newline
    ),

    comment: $ => seq(
      '#',
      /[^#=>\n!][^\n]*/,
      $._newline
    ),

//    instance_var_declaration: $ => seq(
//      '@',
//      $.identifier,
//      '=',
//      /[^\n]*/,
//      $._newline
//    ),
//
//    instance_var_reference: $ => seq(
//      '@',
//      $.identifier
//    ),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    blank_line: $ => $._newline,

    _newline: $ => /\n/,
  }
});
