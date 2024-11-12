/**
 * @file Ruby Tryouts Grammar for Tree-sitter
 * @description Parses Ruby Tryouts test files into an AST. Tryouts is a documentation-focused
 * testing framework where each test case can have descriptions, code blocks and expectations.
 * @license MIT
 */

/**
 *
 * The grammar is now complete and supports:
 * 1. Basic Tryouts functionality
 *    - Setup/teardown sections
 *    - Test cases with descriptions
 *    - Single and multi-line expectations
 *    - Instance variables
 *
 * 2. New Features
 *    - Expected failure cases with messages
 *    - Metadata declarations for:
 *      - Dependencies
 *      - Versions
 *      - Time travel
 *    - Multi-line formatted output
 *
 * 3. Proper Field Names
 *    - All important nodes have named fields
 *    - Error types and messages are properly separated
 *    - Metadata types are clearly defined
 */


/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'ruby_tryouts',

  /**
   * Define what elements should be implicitly handled between tokens
   * In our case, just whitespace
   */
  extras: $ => [/\s/],

  /**
   * Handle ambiguous cases where the parser could match multiple rules.
   * Key conflicts:
   * - code_block vs source_file: Since both can contain sequences of code
   * - setup/teardown vs code_block: Since both can contain code and comments
   */
  conflicts: $ => [
    [$.code_block, $.source_file],
    [$.setup_section, $.code_block],
    [$.teardown_section, $.code_block]
  ],

  /**
   * Establish evaluation order for rules that could overlap.
   * Higher precedence rules are evaluated first.
   */
  precedences: $ => [
    ['test_case'],
    ['code_block'],
    ['code_line']
  ],

  rules: {
    /**
     * A Tryouts file contains:
     * 1. Optional setup section - for shared context and instance vars
     * 2. One or more test cases - the actual tests
     * 3. Optional teardown section - for cleanup
     */
    source_file: $ => seq(
      optional(repeat1($.metadata_declaration)),
      optional(field('setup', $.setup_section)),
      repeat1(field('test_case', $.test_case)),
      optional(field('teardown', $.teardown_section))
    ),

    /**
     * Setup section can contain:
     * - Regular code lines
     * - Comments
     * - Instance variable declarations (preferred location)
     *
     * Uses prec.right to handle nested sequences correctly
     */
    setup_section: $ => prec.right(repeat1(choice(
      $.code_line,
      $.comment,
      $.instance_var_declaration
    ))),

    /**
     * Teardown section can contain:
     * - Regular code lines
     * - Comments
     */
    teardown_section: $ => prec.right(repeat1(choice(
      $.code_line,
      $.comment
    ))),

    /**
     * A test case consists of:
     * 1. Optional description lines starting with ##
     * 2. A code block containing the test code
     * 3. One or more expectations starting with #=> or # =>
     */
    test_case: $ => prec('test_case', seq(
      optional(repeat1($.description)),
      field('code_block', $.code_block),
      repeat1(choice(
        field('expectation', $.expectation),
        field('expected_failure', $.expected_failure)
      ))
    )),

    /**
     * Code blocks can contain:
     * - Regular code lines
     * - Comments
     * - Instance variable references (but not declarations)
     */
    code_block: $ => prec('code_block', repeat1(
      choice(
        $.code_line,
        $.comment,
        $.instance_var_reference
      )
    )),

    /**
     * A line of Ruby code
     * - Excludes lines starting with # (comments)
     * - Excludes lines starting with @ (instance vars)
     * - Preserves the raw Ruby source for later evaluation
     */
    code_line: $ => prec('code_line',
      /[^#@\n][^\n]*/
    ),

    /**
     * Instance variable declarations
     * Format: @variable_name = value
     * Should primarily appear in setup section
     */
    instance_var_declaration: $ => seq(
      '@',
      $.identifier,
      '=',
      $.code_line
    ),

    /**
     * Instance variable references
     * Format: @variable_name
     * Can appear in any code block
     */
    instance_var_reference: $ => seq(
      '@',
      $.identifier
    ),

    /**
     * Ruby identifier rules:
     * - Must start with letter or underscore
     * - Can contain letters, numbers, underscores
     */
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

     /**
    * Three types of comments:
    * 1. Regular comments starting with #
    * 2. Description comments starting with ##
    * 3. Disabled expectations - any of:
    *    - ##=> or ## => (disabled expectation)
    *    - ### (disabled expectation)
    *    - !## (disabled expectation)
    *
    * Note: If all expectations in a test case are disabled,
    * the test runner will skip the entire test case.
    */
    comment: $ => choice(
      seq('#', /[^=>\n!].*/),    // Regular comment (exclude ! for #!>)
      $.description,             // Description comment (##)
      choice(                    // Disabled expectations
        seq('##=>', /[^\n]*/),
        seq('## =>', /[^\n]*/),
        seq('###', /[^\n]*/),
      )
    ),

    /**
     * Test case descriptions
     * - Start with ##
     * - Capture remaining line as description text
     */
    description: $ => seq(
      '##',
      field('text', /[^\n]*/)
    ),

    /**
     * Test expectations
     * - Start with #=> or # =>
     * - Capture expected value
     * - Optionally track pass/fail status
     */
    expectation: $ => choice(
      // Single-line expectation
      seq(
        choice('#=>', '# =>'),
        field('value', /[^\n]*/),
        optional(field('status', choice('pass', 'fail'))),
      ),
      // Multi-line expectation
      seq(
        choice('#=>', '# =>'),
        field('value', seq(
          /[^\n]*/,
          repeat1(seq(
            '\n',
            '#    ',
            /[^\n]*/
          )),
          optional('\n')
        )),
        optional(field('status', choice('pass', 'fail')))
      )
    ),

    /**
     * Expected failure declarations
     * Format: #!> ErrorType[:optional message]
     * Examples:
     *   #!> TypeError
     *   #!> FrozenError: can't modify frozen string
     */
    expected_failure: $ => seq(
      '#!>',
      field('error_type', /[^:\n]*/),  // Restrict to valid error types
      optional(seq(
        ':',
        field('message', /[^\n]*/)
      ))
    ),

    /**
     * Metadata declarations
     * Format: # @type value
     * Types:
     * - requires: gem dependencies
     * - version: minimum version requirement
     * - ruby: Ruby version requirement
     * - at: time travel timestamp
     * - timezone: explicit timezone setting
     */
    metadata_declaration: $ => choice(
      // Dependencies
      seq(
        '# @',
        field('type', choice(
          'requires',
          'version',
          'ruby'      // For specifying Ruby version
        )),
        field('value', /[^\n]*/)
      ),
      // Time travel
      seq(
        '# @',
        field('type', choice(
          'at',
          'timezone'  // For explicit timezone setting
        )),
        field('value', /[^\n]*/)
      )
    ),

  }
});
