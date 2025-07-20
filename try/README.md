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

### edge_cases/
Tests for error handling and edge cases:
- `error_handling_try.rb` - Deliberate failures, exceptions

### features/
Tests for specific framework features:
- `fails_mode_try.rb` - Tests for fails mode functionality

### utilities/
Tests for internal functionality:
- `debug_teardown_try.rb` - Teardown detection tests
- `test_context_modes_try.rb` - Fresh vs shared context tests
- `test_setup_execution1_try.rb` - TestBatch execution tests
- `test_setup_execution2_try.rb` - Fresh context execution tests

## Running Tests

```bash
# Run all tests
bundle exec tryouts try/

# Run specific category
bundle exec tryouts try/core/
bundle exec tryouts try/parsing/
bundle exec tryouts try/edge_cases/
bundle exec tryouts try/features/

# Run utilities (debug scripts)
ruby try/utilities/debug_teardown.rb
```

## Adding New Tests

Place new test files in the appropriate category:
- Core framework functionality → `core/`
- Parsing/syntax features → `parsing/`
- Error handling/edge cases → `edge_cases/`
- Framework features → `features/`
- Debug/testing utilities → `utilities/`
