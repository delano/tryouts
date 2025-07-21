# try/README.md
---
# Tryouts Test Organization

This directory contains the test suite for Tryouts v3.0, organized by functionality for better maintainability and discoverability.

## Running Tests

```bash
# All tests
try

# By directory or file
try try/core/
try try/core/advanced_syntax_try.rb

# Noise, more or less
try -v  # verbose mode includes the source code, expected and actual output.,
try -vf # verbose, only for failed tests
try -q  # quiet mode, just dots and end result
try -q  2> /dev/null # if you only care about the exit code
```

To integrate with existing CI workflows or for old school homies, run the tests as rspec or minitest.

```bash
try --rspec
try --minitest

# Or generate the test files for later
try --generate-rspec try/core/basic_syntax_try.rb > spec/basic_syntax_spec.rb
try --generate-minitest try/core/basic_syntax_try.rb > test/basic_syntax_test.rb
```

## Test Content Guidelines

- Tests should read like documentation
- Use descriptive comments and test case descriptions
- Group related functionality within files
- Avoid test framework specific code (mocks, harnesses)
- Know your expectation types and their behaviour. All testcases are not created equally.
- Follow the pattern `*_try.rb` to be automatically discovered by the Tryouts framework.
