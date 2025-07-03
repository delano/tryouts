# Tryouts v3.0.0-pre

**Ruby tests that read like documentation.**

A modern test framework for Ruby that uses comments to define expectations. Tryouts are meant to double as documentation, so the Ruby code should be plain and reminiscent of real code.

> [!WARNING]
> Version 3.0 uses Ruby's Prism parser and pattern matching, requiring Ruby 3.4+

## Key Features

- **Documentation-style tests** using comment-based expectations (`#=>`)
- **Framework integration** with RSpec and Minitest translators
- **Modern Ruby architecture** using Prism parser and pattern matching
- **Immutable data structures** with `Data.define` classes
- **Enhanced error reporting** with line numbers and context

## Installation

Add to your Gemfile:
```ruby
gem 'tryouts', '~> 3.0.0-pre'
```

Or install directly:
```bash
gem install tryouts --pre
```

From source:
```bash
git clone https://github.com/delano/tryouts.git
cd tryouts
bundle install
```

## Requirements

- **Ruby >= 3.4.4** (for Prism parser and pattern matching)
- **RSpec** or **Minitest** (optional, for framework integration)

## Usage

### Basic Commands

```bash
# Auto-discover and run all tests
try

# Run specific test file
try try/step1_try.rb

# Framework integration
try --rspec try/step1_try.rb      # Run with RSpec
try --minitest try/step1_try.rb   # Run with Minitest

# Code generation only
try --generate-rspec try/step1_try.rb
try --generate-minitest try/step1_try.rb

# Output options
try -v    # verbose (includes source code and return values)
try -q    # quiet mode
try -f    # show failures only
try -D    # debug mode
```

### Exit Codes

- `0`: All tests pass
- `1+`: Number of failing tests

## Writing Tests

Tryouts use a unique comment-based expectation syntax:

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

- **Setup Section**: Code before first test case (accessible via instance variables)
- **Test Cases**: Description lines (`##`), Ruby code, and expectations (`#=>`)
- **Teardown Section**: Code after last test case

## Framework Integration

Version 3.0 introduces framework translators that convert tryouts into established test frameworks:

### RSpec Integration

```bash
try --rspec file_try.rb
```

Generates RSpec `describe/it` blocks with full RSpec ecosystem support including:
- Mocking and stubbing
- Custom matchers
- Parallel execution
- IDE integration

### Minitest Integration

```bash
try --minitest file_try.rb
```

Creates Minitest classes with `test_*` methods for:
- Standard assertions
- Custom test cases
- CI/CD integration
- Debugging support

### Direct Mode

```bash
try file_try.rb  # Original tryouts execution
```

Uses shared execution context with all tests running in the same environment.

## File Discovery

Auto-discovers test files matching these patterns:
- `./try/*_try.rb`
- `./tryouts/*_try.rb`
- `./*_try.rb`

Files are processed in lexical order.

## Modern Architecture (v3.0)

### Core Components

- **Prism Parser**: Native Ruby parsing with pattern matching for line classification
- **Data Structures**: Immutable `Data.define` classes for test representation
- **Framework Translators**: Convert tryouts to RSpec/Minitest format
- **CLI**: Modern command-line interface with framework selection

### Ruby 3.4+ Features

- **Pattern matching** throughout parsing and classification logic
- **Prism native parser** (no external grammar compilation)
- **Data.define classes** for immutable data structures
- **Enhanced error context** with line numbers and suggestions

## Development

### Running Tests

```bash
# Test framework using itself
try try/*_try.rb

# With coverage
COVERAGE=1 try try/*_try.rb
```

### Code Quality

```bash
bundle exec rubocop        # Check style
bundle exec rubocop -A     # Auto-fix issues
```

## Migration from v2.x

Version 3.0 represents a complete modernization:

- **Parser**: Tree-sitter → Prism (native Ruby)
- **Execution**: Custom runner → Framework delegation
- **Data**: Traditional classes → `Data.define` immutable structures
- **Syntax**: Standard Ruby → Pattern matching throughout
- **Ruby**: 2.7+ → 3.4+ requirement

## Examples

For real-world usage examples, see:
- [Onetimesecret tryouts](https://github.com/onetimesecret/onetimesecret/)
- Test files in this repository: `try/*_try.rb` and `doc/`

## AI Development Assistance

This version of Tryouts was developed with assistance from AI tools. The following tools provided significant help with architecture design, code generation, and documentation:

- **Claude Sonnet 4** - Architecture design, code generation, and documentation
- **Claude Desktop & Claude Code** - Interactive development sessions and debugging
- **GitHub Copilot** - Code completion and refactoring assistance
- **Qodo Merge Pro** - Code review and quality improvements

I remain responsible for all design decisions and the final code. I believe in being transparent about development tools, especially as AI becomes more integrated into our workflows as developers.
