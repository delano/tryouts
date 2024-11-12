/**
 * @file Ruby Tryouts Grammar for Tree-sitter
 * @description Parses Ruby Tryouts test files into an AST. Tryouts is a documentation-focused
 * testing framework where each test case can have descriptions, code blocks and expectations.
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'ruby_tryouts',

  /**
   * Implicitly handled elements between tokens.
   * Currently only handles standard whitespace characters.
   * Note: Extend this if additional ignorable elements are needed.
   */
  extras: $ => [/\s/],

  /**
   * Resolution rules for ambiguous parsing scenarios.
   * These conflicts are intentional and tell tree-sitter how to handle overlapping patterns.
   *
   * Key ambiguities handled:
   * 1. code_block vs source_file: Both can contain arbitrary Ruby code
   * 2. setup/teardown vs code_block: Both can contain similar elements
   */
  conflicts: $ => [
    [$.setup_section, $.code_block],
    [$.teardown_section, $.code_block],
    [$.comment, $.test_case]
  ],

  /**
   * Precedence rules for overlapping patterns.
   * Higher precedence = evaluated first.
   * Critical for correct parsing of nested structures.
   */
  precedences: $ => [
    ['comment'], // Highest precedence
    ['test_case'],
    ['code_block'],
    ['code_line']
  ],

  rules: {
    /**
     * Root node of a Tryouts file.
     * Structure:
     * 1. Optional metadata declarations (@requires, @version, etc.)
     * 2. Optional setup section for shared context
     * 3. One or more test cases (required)
     * 4. Optional teardown section for cleanup
     */
    source_file: $ => seq(
      optional(repeat1($.metadata_declaration)),
      optional(field('setup', $.setup_section)),
      repeat1(field('test_case', $.test_case)),
      optional(field('teardown', $.teardown_section))
    ),

    /**
     * Setup section for shared test context.
     * Can contain:
     * - Ruby code lines
     * - Comments/documentation
     * - Instance variable declarations (preferred location)
     *
     * Uses prec.right to handle nested code sequences correctly.
     * Critical for proper AST construction with multiple lines.
     */
    setup_section: $ => prec.right(repeat1(choice(
      $.code_line,
      $.comment,
      $.instance_var_declaration
    ))),

    /**
     * Teardown section for test cleanup.
     * Can contain:
     * - Ruby code lines
     * - Comments/documentation
     *
     * Note: Instance variables can be referenced but not declared here.
     */
    teardown_section: $ => prec.right(repeat1(choice(
      $.code_line,
      $.comment
    ))),

    /**
     * Individual test case structure.
     * Components:
     * 1. Optional description lines (##)
     * 2. Required code block with test implementation
     * 3. One or more expectations (#=>) or expected failures (#!>)
     *
     * Example:
     * ## Tests string concatenation
     * "hello" + " world"
     * #=> "hello world"
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
     * Code block container.
     * Holds executable Ruby code and can include:
     * - Standard code lines
     * - Comments/documentation
     * - Instance variable references
     *
     * Note: Distinguished from setup/teardown by context and content restrictions
     */
    code_block: $ => prec('code_block', repeat1(
      choice(
        $.code_line,
        $.comment,
        $.instance_var_reference
      )
    )),

    /**
     * Single line of Ruby code.
     * Restrictions:
     * - Cannot start with # (comments)
     * - Cannot start with @ (instance vars)
     * - Preserves raw source for evaluation
     *
     * Note: Newlines are significant for parsing
     */
    code_line: $ => prec('code_line',
      /[^#@\n][^\n]*/
    ),

    /**
     * Instance variable declaration.
     * Format: @variable_name = value
     *
     * Example:
     * @user = User.new
     * @count = 42
     *
     * Note: Should primarily appear in setup section
     */
    instance_var_declaration: $ => seq(
      '@',
      $.identifier,
      '=',
      $.code_line
    ),

    /**
     * Instance variable reference.
     * Format: @variable_name
     *
     * Example:
     * @user.name
     * @count + 1
     *
     * Can appear in any code block after declaration
     */
    instance_var_reference: $ => seq(
      '@',
      $.identifier
    ),

    /**
     * Ruby identifier pattern.
     * Rules:
     * - Must start with letter or underscore
     * - Can contain letters, numbers, underscores
     * - Case sensitive
     */
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    /**
     * Comment variations.
     * Types:
     * 1. Standard comments (#)
     * 2. Description comments (##)
     * 3. Disabled expectations:
     *    - ##=> or ## => (disabled expectation)
     *    - ### (disabled expectation)
     *
     * Note: Disabled expectations will cause test case to be skipped
     * if all expectations are disabled
     */
    comment: $ => choice(
      seq('#', /[^=>\n!].*/),    // Standard comment
      $.description,              // Description comment
      choice(                     // Disabled expectations
        seq('##=>', /[^\n]*/),
        seq('## =>', /[^\n]*/),
        seq('###', /[^\n]*/)
      )
    ),

    /**
     * Test case description.
     * Format: ## Description text
     *
     * Example:
     * ## This test verifies user authentication
     *
     * Used for documentation and test organization
     */
    description: $ => seq(
      '##',
      field('text', /[^\n]*/)
    ),

    /**
     * Test expectations.
     * Formats:
     * 1. Single line: #=> expected_value
     * 2. Multi-line: #=> start
     *                #    continued...
     *
     * Can include optional pass/fail status for tooling
     */
    expectation: $ => choice(
      // Single-line format
      seq(
        choice('#=>', '# =>'),
        field('value', /[^\n]*/),
        optional(field('status', choice('pass', 'fail'))),
      ),
      // Multi-line format
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
     * Expected failure declarations.
     * Format: #!> ErrorType[:optional message]
     *
     * Examples:
     * #!> TypeError
     * #!> FrozenError: can't modify frozen string
     * #!> ArgumentError: wrong number of arguments
     *
     * Used to test error conditions and exceptions
     */
    expected_failure: $ => seq(
      '#!>',
      field('error_type', /[^:\n]*/),
      optional(seq(
        ':',
        field('message', /[^\n]*/)
      ))
    ),

    /**
     * Metadata declarations for test requirements and configuration.
     * Format: # @type value
     *
     * Types:
     * - @requires: Gem dependencies
     * - @version: Minimum version requirement
     * - @ruby: Required Ruby version
     * - @at: Time travel timestamp
     * - @timezone: Timezone setting
     *
     * Examples:
     * # @requires activerecord >= 6.0
     * # @ruby 2.7.0
     * # @at 2024-01-01 12:00:00
     * # @timezone UTC
     */
    metadata_declaration: $ => choice(
      // Dependency declarations
      seq(
        '# @',
        field('type', choice(
          'requires',
          'version',
          'ruby'
        )),
        field('value', /[^\n]*/)
      ),
      // Time travel
      seq(
        '# @',
        field('type', choice(
          'at',
          'timezone'
        )),
        field('value', /[^\n]*/)
      )
    ),
  }
});
