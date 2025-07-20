# Tryouts Test Organization

This directory contains organized test files for the Tryouts library.

## Structure

### core/
Tests for core framework functionality:
- `class_try.rb` - Core Tryouts class methods, attributes, debug/trace
- `console_try.rb` - ANSI colors, formatting, path utilities

### parsing/
Tests for parsing and syntax features:
- `basic_syntax_try.rb` - Basic expectations, setup/teardown
- `advanced_features_try.rb` - Exceptions, helpers, multiple expectations
- `multiline_try.rb` - Multi-line code blocks

## Running Tests

```bash
# Run all tests
bundle exec tryouts try/

# Run specific category
bundle exec tryouts try/core/
bundle exec tryouts try/parsing/

# Run specific test file
bundle exec tryouts try/core/class_try.rb
```

## Adding New Tests

Place new test files in the appropriate category:
- Core framework functionality → `core/`
- Parsing/syntax features → `parsing/`
