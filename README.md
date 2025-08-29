# Tryouts v3

**Ruby tests that read like documentation.**

A modern test framework for Ruby that uses comments to define expectations. Tryouts are meant to double as documentation, so the Ruby code should be plain and reminiscent of real code.

> [!NOTE]
> **Agent-Optimized Output**: Tryouts includes specialized output modes for LLM consumption with `--agent` flag, providing structured, token-efficient test results that are 60-80% smaller than traditional output while preserving debugging context.

> [!WARNING]
> Version 3.0+ uses Ruby's Prism parser and pattern matching, requiring Ruby 3.2+

## Key Features

- **Documentation-style tests** using comment-based expectations (`#=>`)
- **Great expectation syntax** for more expressive assertions (`#==>` for true, `#=/=>` for false, `#=:>` for class/module)
- **Framework integration** write with tryouts syntax, run with RSpec or Minitest
- **Agent-optimized output** structured, token-efficient output for LLM consumption
- **Enhanced error reporting** with line numbers and context

## Installation

```ruby
# Add to your Gemfile:
gem 'tryouts'
```

```bash
# Or install directly:
$ gem install tryouts
```

## Usage

```bash
# Auto-discover and run all tests
try

# Run specific test file
try try/core/basic_syntax_try.rb
```

## Writing Tests

Tryouts use a comment-based syntax for expecations:

```ruby
# Setup code runs before all tests
puts 'Setup running'

## Simple test with expectation
a = 1 + 1
#=> 2

## Multi-line test with description
## TEST: Addition works correctly
a = 1
b = 2
a + b
#=> 3

## Testing object methods
'hello'.upcase
#=> 'HELLO'

## Expressions are evaluated
81
#=> 9 * 9

## Testing errors with rescue
begin
  raise RuntimeError, "test error"
rescue RuntimeError
  :caught
end
#=> :caught

# Teardown runs after all tests
puts 'Cleanup complete'
```

### Test Structure

Each test file is made up of three sections:
- **Setup**: Code before first test case
- **Test Cases**: Description lines (`##`), Ruby code, and expectations (`#=>`)
- **Teardown**: Code after last test case

### Great Expectations System

  | Syntax | Description                | Example                             | Context       |
  |--------|----------------------------|-------------------------------------|---------------|
  | `#=>`  | Traditional value equality | `#=> [1, 2, 3]`                     | result, _     |
  | `#==>` | Must be exactly true       | `#==> result.include?(2)`            | result, _     |
  | `#=/=>`| Must be exactly false      | `#=/=> _.empty?`                     | result, _     |
  | `#=\|>` | Must be true OR false     | `#=\|> 0.positive?`                   | result, _     |
  | `#=!>` | Must raise an exception    | `#=!> error.is_a?(ZeroDivisionError)` | error         |
  | `#=:>` | Must match result type     | `#=:> String`                         | result, _     |
  | `#=~>` | Must match regex pattern   | `#=~> /^[^@]+@[^@]+\.[^@]+$/`         | result, _     |
  | `#=%>` | Must complete within time  | `#=%> 2000 # in milliseconds`         | result, _     |
  | `#=1>` | Match content in STDOUT    | `#=1> "You have great success"`       | result, _     |
  | `#=2>` | Match content in STDERR    | `#=2> /[a-zA-Z0-9]+-?[0-9]{1,5}`      | result, _     |
  | `#=<>` | Fails on purpose           | `#==<> result.include?(4)`            | result, _     |


### Using other test runners

Version 3 introduces framework translators that convert tryouts into the equivalent tests in popular test tools, like RSpec and Minitest.

```bash
# Framework integration
try --rspec try/core/basic_syntax_try.rb      # Run with RSpec
try --minitest try/core/basic_syntax_try.rb   # Run with Minitest

# Code generation only
try --generate-rspec try/core/basic_syntax_try.rb > spec/basic_syntax_spec.rb
try --generate-minitest try/core/basic_syntax_try.rb > test/basic_syntax_test.rb

# Output options
try -v    # verbose (includes source code and return values)
try -q    # quiet mode
try -f    # show failures only
try -D    # debug mode

# Agent-optimized output for LLMs
try --agent                              # structured, token-efficient output
try --agent --agent-focus summary        # show only counts and problem files
try --agent --agent-focus first-failure  # show first failure per file
try --agent --agent-focus critical       # show only errors/exceptions
try --agent --agent-limit 1000          # limit output to 1000 tokens
```

### Exit Codes

- `0`: All tests pass
- `1+`: Number of failing tests


## Requirements

- **Ruby >= 3.2** (for Prism parser and pattern matching)
- **RSpec** or **Minitest** (optional, for framework integration)

## Modern Architecture (v3+)

### Core Components

- **Prism Parser**: Native Ruby parsing with pattern matching for line classification
- **Data Structures**: Immutable `Data.define` classes for test representation
- **Framework Translators**: Convert tryouts to RSpec/Minitest format
- **CLI**: Modern command-line interface with framework selection


## Live Examples

For real-world usage examples, see:
- [Onetimesecret tryouts](https://github.com/onetimesecret/onetimesecret/)
- [Rhales](https://github.com/onetimesecret/rhales)
- [Familia](https://github.com/delano/familia)

## AI Development Assistance

This version of Tryouts was developed with assistance from AI tools. The following tools provided significant help with architecture design, code generation, and documentation:

- **Claude Sonnet 4** - Architecture design, code generation, and documentation
- **Claude Desktop & Claude Code** - Interactive development sessions and debugging
- **GitHub Copilot** - Code completion and refactoring assistance
- **Qodo Merge Pro** - Code review and quality improvements

I remain responsible for all design decisions and the final code. I believe in being transparent about development tools, especially as AI becomes more integrated into our workflows as developers.
