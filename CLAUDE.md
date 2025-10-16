# CLAUDE.md

Ruby 3.2+ only

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tryouts v3.0 is a modern Ruby test framework that allows writing tests in documentation-style format using comments. Tests read like documentation where expectations are written as comments (`#=>`) following Ruby code blocks. This version represents a complete modernization from tree-sitter to Prism parser with Ruby 3.4+ features.

Tryouts are meant to double as documentation so the ruby code should be plain and reminiscent of real code. i.e. avoid using mocks, harnesses, and any test-code tropes.

Github link: https://github.com/delano/tryouts

NOTE: Do not say things like, "You're absolutely right!".

## Architecture

### Core Components
- **Prism Parser** (`lib/tryouts/prism_parser.rb`): Native Ruby parsing with pattern matching for line classification
- **Data Structures** (`lib/tryouts/data_structures.rb`): Modern `Data.define` classes for immutable structures
- **Translators** (`lib/tryouts/translators/`): Framework translators for RSpec and Minitest
- **CLI** (`lib/tryouts/cli.rb`): Modern command-line interface with framework selection
- **Formatters** (`lib/tryouts/cli/formatters/`): Output management system

### Modern Ruby Features Used
- Pattern matching throughout (`case...in` syntax) for parsing and classification
- `Data.define` classes for immutable data structures
- Prism native parser (no external grammar compilation needed)
- Ruby 3.4+ syntax and idioms

## Writing tests (Coles Notes)

**Tryouts framework rules:**
1. **Structure**: Each file has 3 sections - setup (optional), testcases, teardown (optional); each testcase has 3 required parts: description, code, expectations.
2. **Test cases**: Use `##` line prefix for test descriptions, Ruby code, then `#=>` expectations
3. **Variables**: Instance variables (`@var`) persist across sections; local variables do not.
4. **Expectations**: Multiple expectation types available (`#=>`, `#==>`, `#=:>`, `#=!>`, etc.); each testcase can have multiple expectations.
5. **Comments**: Use single `#` prefix, but DO NOT label file sections
6. **Philosophy**: Plain realistic code, avoid mocks/test DSL
7. **Result**: Last expression in each test case is the result

**Running tests:**
- **Basic**: `bundle exec try` (auto-discovers `*_try.rb` and `*.try.rb` files)
- **All options**: `bundle exec try --help` (complete CLI reference with agent-specific notes)

**Agent-optimized workflow:**
- **Default agent mode**: `bundle exec try --agent` (structured, token-efficient output for LLMs)
- **Focus modes**: `bundle exec try --agent --agent-focus summary` (options: `summary|first-failure|critical`)
  - `summary`: Overview of test results only
  - `first-failure`: Stop at first failure with details
  - `critical`: Only show critical issues and summary
- **Framework tips**: `bundle exec try --agent --agent-tips` (includes reminders about instance variables, multiple expectations, exception testing)

**Framework integration:**
- **RSpec**: `bundle exec try --rspec` (generates RSpec-compatible output)
- **Minitest**: `bundle exec try --minitest` (generates Minitest-compatible output)

**Debugging options:**
- **Stack traces**: `bundle exec try -s` (stack traces without debug logging)
- **Debug mode**: `bundle exec try -D` (additional logging including stack traces)
- **Verbose failures**: `bundle exec try -vf` (detailed failure output)
- **Fresh context**: `bundle exec try --fresh-context` (isolate test cases)

*Note: Use `--agent` mode for optimal token efficiency when analyzing test results programmatically.*


## Development Commands

### Running Tests
```bash
# Run all tryouts tests (verbose, failures only)
~/.rbenv/shims/ruby ./exe/try -vf

# Run specific test categories
~/.rbenv/shims/ruby ./exe/try -v try/core/
~/.rbenv/shims/ruby ./exe/try -v try/expectations/
~/.rbenv/shims/ruby ./exe/try -v try/formatters/

# Run specific test file
~/.rbenv/shims/ruby ./exe/try -v try/core/basic_syntax_try.rb
~/.rbenv/shims/ruby ./exe/try -v try/expectations/boolean_expectations_try.rb

# Run with framework integration
~/.rbenv/shims/ruby ./exe/try -v --rspec try/core/basic_syntax_try.rb
~/.rbenv/shims/ruby ./exe/try -v --minitest try/expectations/type_expectations_try.rb

# Code generation only (no execution)
~/.rbenv/shims/ruby ./exe/try -v --generate-rspec try/core/basic_syntax_try.rb
~/.rbenv/shims/ruby ./exe/try -v --generate-minitest try/expectations/performance_timing_try.rb
```

### Development Tools
```bash
# Install dependencies
bundle install

# Code formatting and linting
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix

# Interactive debugging
bundle exec pry
```

```bash
# Ruby
rbenv local 3.4.4
/Users/d/.rbenv/shims/ruby
```


### Testing the Framework
```bash
# Test framework using itself
try try/

# Test with different output modes
try -v  # verbose, includes source code and return values
try -q  # quiet
try -f  # show failures only
try -D  # debug mode

# Test specific areas
try try/core/          # Core functionality
try try/expectations/  # All expectation types
try try/formatters/    # Output formatting

# Run with code coverage
COVERAGE=1 try try/
```

## Additional Context

### Test File Format

Tryouts uses a unique comment-based expectation syntax with multiple expectation types:

```ruby
# Setup code runs before all tests
puts 'Setup running'

# Basic equality expectation
a = 1 + 1
#=> 2

# Boolean expectations (strict true/false)
[1, 2, 3]
#==> result.length == 3  # Must be exactly true
#=/=> result.empty?      # Must be exactly false
#=|> result.include?(2)  # Must be true OR false (boolean)

# Type checking
"hello"
#=:> String

# Regex matching
"user@example.com"
#=~> /\A[^@]+@[^@]+\.[^@]+\z/

# Performance timing (10% tolerance)
sleep(0.01)
#=%> 15  # Allow up to 15ms

# Exception handling
lambda { raise "error" }
#=!> RuntimeError

## Multi-line test with description
## TEST: Addition works correctly
a = 1
b = 2
a + b
#=> 3
#=> result  # Variable access

# Teardown runs after all tests
puts 'Cleanup complete'
```

### Framework Translation

The core philosophy is using Tryouts as a preprocessor/transpiler:

- **RSpec Mode**: Generates `describe/it` blocks, leverages RSpec's full ecosystem
- **Minitest Mode**: Creates test classes with `test_*` methods
- **Direct Mode**: Original tryouts execution with shared context

This approach provides IDE support, debugging capabilities, and CI/CD integration through mature test frameworks.

### Test Organization

Test files are organized into logical directories:

- **`try/core/`** - Core framework functionality (9 files)
- **`try/expectations/`** - All expectation types (7 files)
- **`try/formatters/`** - Output formatting (2 files)
- **`try/translators/`** - Framework translation (future)

Auto-discovers test files matching: `./{try,tryouts,.}/*_try.rb`
Files are processed in lexical order.

### Exit Codes
- `0`: All tests pass
- `1+`: Number of failing tests

### Key Dependencies
- **Ruby** (>= 3.4.4)
- **prism** (~> 1.0): Native Ruby parser
- **rspec**, **minitest**: Framework integration
- **rubocop**: Code quality with performance and thread safety extensions

## Things to AVOID
* Prematurely declaring the project is complete or production ready
* Backwards compatibility
