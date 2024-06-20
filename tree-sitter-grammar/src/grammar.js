module.exports = grammar({
    name: 'tryouts_lang',

    extras: $ => [
      /\s|\\r?\\n/, // Include whitespace and newlines as ignored characters
    ],

    rules: {
      document: $ => repeat($._element),

      _element: $ => choice(
        $.test_block
      ),

      test_block: $ => seq(
        $.test_title,
        $.ruby_code,
        repeat1($.test_expectation)
      ),

      test_title: $ => /##[^\n]*(\n##[^\n]*)*/,

      ruby_code: $ => /[^#]+/,

      test_expectation: $ => /#=>.*/,
    }
  });
