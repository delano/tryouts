module.exports = {
  name: 'tryouts',

  file_types: ['.rb'],

  content_regex: /^## .*\n.*#=> /m,

  highlights: {
    'tryout_description': 'markup.heading',
    'expectation': 'markup.inserted',
    'comment': 'comment',
    'require_statement': 'keyword.control',
    'string_literal': 'string',
    'assignment_statement': 'variable',
    'configuration_statement': 'entity.name.class'
  },

  folds: {
    'tryout_block': {
      start: /^## /,
      end: /^#=> /
    },
    'setup_section': {
      start: /^# /,
      end: /^## /
    }
  },

  symbols: {
    'tryout_description': {
      symbol: 'method'
    },
    'assignment_statement': {
      symbol: 'variable'
    }
  },

  lint_rules: {
    'require_expectation': {
      level: 'error',
      message: 'Each tryout block must have an expectation (#=>)',
      query: `(tryout_block (!expectation))`
    },
    'single_expectation': {
      level: 'warning',
      message: 'Tryout blocks should have exactly one expectation',
      query: `(tryout_block expectation+ @second_expectation)`
    }
  }
}
