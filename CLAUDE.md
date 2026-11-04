# CLAUDE.md

Ruby 3.2+ only

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tryouts v3.0 is a modern Ruby test framework that allows writing tests in documentation-style format using comments. Tests read like documentation where expectations are written as comments (`#=>`) following Ruby code blocks. This version represents a complete modernization from tree-sitter to Prism parser with Ruby 3.2+ features.

Tryouts are meant to double as documentation so the ruby code should be plain and reminiscent of real code. i.e. avoid using mocks, harnesses, and any test-code tropes.

Github link: https://github.com/delano/tryouts

NOTE: Do not say things like, "You're absolutely right!".

## Architecture

### Core Components
- **Statement Parser** (`lib/tryouts/parsers/statement_parser.rb`): Parses the file once with Prism and anchors every comment to a top-level statement (trailing on its line, or in the gap after it). That yields setup, test cases, interludes and teardown, plus parser warnings
- **Data Structures** (`lib/tryouts/test_case.rb`, `lib/tryouts/parser_warning.rb`): `Data.define` classes `Testrun`, `Setup`, `TestCase`, `OrphanBlock` (interlude), `Teardown`, `Expectation`, `ParserWarning`
- **Execution** (`lib/tryouts/test_batch.rb`, `lib/tryouts/script_binding.rb`): Runs a file in one binding (shared context), or a fresh object and binding per test
- **Expectation Evaluators** (`lib/tryouts/expectation_evaluators/`): One class per operator; `evaluation_context.rb` compiles each expectation into a lambda in the test's binding
- **Translators** (`lib/tryouts/translators/`): Framework translators for RSpec and Minitest
- **CLI** (`lib/tryouts/cli.rb`): Modern command-line interface with framework selection
- **Formatters** (`lib/tryouts/cli/formatters/`): Output management system

### Modern Ruby Features Used
- Pattern matching (`case...in` syntax) for parsing and classification
- `Data.define` classes for immutable data structures
- Prism native parser (no external grammar compilation needed)
- Ruby 3.2+ syntax and idioms

## Writing tests (Coles Notes)

**Execution model:** a tryouts file is a Ruby script. It runs top to bottom in one binding, so local and instance variables persist from each statement to the next. An expectation comment asserts on the value of the top-level statement above it, or of the statement it trails on the same line. A `##` comment names the test case that ends at the next expectation.

**Tryouts framework rules:**
1. **Structure**: Statements before the first test case are setup (optional); statements after the last expectation are teardown (optional). Each test case has a `##` description, code, and one or more expectations.
2. **Test cases**: A `##` line, Ruby code, then expectations (`#=>` etc.) on the lines below the last statement, or trailing it on the same line (`1 + 1 #=> 2`). `# =>` with a space is the same as `#=>`. `##` lines on adjacent lines join into one description, also across a bare `##` spacer line; a blank line or plain `#` line ends the block. An expectation directly under a `##` with no code between them does not apply to the test above; it is a warning and a failing test. A bare `##` is a plain comment. In strict mode (the default) an expectation without a `##` description is an error.
3. **Variables**: Local and instance variables both persist, across setup, tests, interludes and teardown. Expectations see the test's locals.
4. **Result**: The value of the last statement in the test case. Inside an expectation it is `result` (or `_`); `error` is the exception the test raised, or nil; `elapsed_ms` is the run time.
5. **Expectations**: Multiple expectation types available (`#=>`, `#==>`, `#=:>`, `#=!>`, etc.); each test case can have several, and all must pass.
6. **Script scope**: The file runs at the top level like a script: `class Foo` is `::Foo`, top-level `include` mixes into Object. A top-level `def` is a method on the file's own main object (the test's own object in fresh context), not on Object: top-level code and blocks can call it, a class the file defines cannot, so pass values in. Classes and constants the file defines are global and stay defined for the rest of the run, as when Ruby loads several files, so a later file sees them; give classes distinct names across files (files run together under `-j`/`--parallel` share them too). Fresh context removes the file's own top-level constants before it re-runs the setup for each later test, so class definitions run again (an `inherited` hook sees every re-run); constants nested in an existing namespace (`JSON::Point`) are not removed. Reopened existing classes stay changed. Top-level `using` raises; use it inside a class or module body. `BEGIN { }` runs with the section it is in, not before the file, and `DATA` is not defined (the text after `__END__` is ignored). Leading magic comments (`# frozen_string_literal: true`) apply to every section and expectation, also under `--rspec`/`--minitest`.
7. **Interludes**: Code between one test's expectations and the next `##` runs in order, before the next test. If it raises (or setup raises), the file stops and fails; the tests left are reported as not run.
8. **Comments**: A single `#` is always a plain comment. DO NOT label file sections. `# TEST:` is not a description; write `##`.
9. **Exceptions**: `#=!>` passes only when the test code itself raises, any exception but a signal or `exit` (a class inheriting from `Exception` directly counts). A lambda or proc that would raise is just a value. A `Timeout::Error` from the test code is reported as itself; the framework's own 30-second per-test deadline is an error.
10. **Philosophy**: Plain realistic code, avoid mocks/test DSL

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
- **Re-run command**: `bundle exec try --agent --agent-command` (outputs copy-paste command for re-running failures with -vfs)
- **Suppress failures**: `bundle exec try --agent --agent-no-failures` (hides detailed failure list, shows summary/command only)

**Framework integration:**
- **RSpec**: `bundle exec try --rspec` (runs the file as RSpec examples; exits non-zero when one fails)
- **Minitest**: `bundle exec try --minitest` (runs the file as Minitest tests)

**Debugging options:**
- **Stack traces**: `bundle exec try -s` (stack traces without debug logging)
- **Debug mode**: `bundle exec try -D` (additional logging including stack traces)
- **Verbose failures**: `bundle exec try -vf` (detailed failure output)
- **Fresh context**: `bundle exec try --no-shared-context` (each test gets a new object and binding; setup, then each interlude above the test, re-run into it, and teardown runs after it)
- **Parallel**: `bundle exec try -j 4` or `--parallel=4` (files run on 4 threads; `-j` alone uses one per CPU; `--parallel 4` with a space reads 4 as a file; flags bundled after `-j` stay flags: `-jvf` is `-j -vf`, `-j4v` is `-j4 -v`)
- **Lenient parsing**: `bundle exec try --no-strict` (allow expectations without a `##` description)
- **Structure**: `bundle exec try --inspect` (show the test cases, setup and teardown the parser found, without running)

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
rbenv local 3.2.0
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

Tryouts uses comment-based expectations with several operators. Every test case in this example passes, in shared and in fresh context:

```ruby
# Statements above the first test run first, in the same binding as the tests
require 'json'

prices = { apple: 1.25, pear: 0.75 }
@cart  = []

## Equality: the value of the statement above is compared with ==
prices[:apple] + prices[:pear]
#=> 2.0

## An expectation can trail its statement on the same line
prices.keys.size #=> 2

## Several statements make one test case
## and the last one is its result
@cart << :apple
@cart << :pear
@cart.size
#=> 2
#==> result == @cart.length    # must be exactly true
#=/=> @cart.empty?             # must be exactly false
#=|> @cart.include?(:apple)    # must be true or false

## Expectations see the test's local variables
subtotal = prices.values.sum
subtotal * 2
#=> subtotal + subtotal

## Type check and regex match (against result.to_s)
JSON.generate(prices)
#=:> String
#=~> /"apple":1.25/

## Performance: a limit in milliseconds, with 10% tolerance
sleep(0.01)
#=%> 15

## Exceptions: the test code itself raises
Integer('twelve')
#=!> ArgumentError
#=~> /invalid value for Integer/
#==> error.message.include?('twelve')

## Non-nil
prices.fetch(:apple)
#=*>

## Output written to stdout
puts "#{prices.size} fruits in stock"
#=1> "2 fruits in stock"

## Negation: must not equal
@cart.size
#=<> 3

# Statements after the last expectation run last
@cart.clear
```

### Expectation operators

`result` (or `_`) is the test's value, `error` the exception it raised (or nil), `elapsed_ms` its run time. Expressions run in the test's binding, so they see its local and instance variables.

| Operator | Passes when |
|---|---|
| `#=> expr` | `result == expr` |
| `#==> expr` | expr is exactly `true` |
| `#=/=> expr` | expr is exactly `false` |
| `#=\|> expr` | expr is `true` or `false` |
| `#=!> Class` | the test code raised an instance of Class (or Module). `#=!> expr` passes when expr is truthy. Fails if nothing was raised; the code is never re-run |
| `#=<> expr` | negation: a Regexp must not match `result.to_s`; a true/false expr on a non-boolean result must be false; otherwise `result != expr` |
| `#=:> Class` | `result.is_a?(Class)`, with the constant resolved in the test's binding |
| `#=~> /re/` | `/re/` matches `result.to_s`, or the exception message when the test raised |
| `#=%> ms` | the test ran within `ms` milliseconds, plus 10% tolerance |
| `#=*>` | `result` is not nil |
| `#=1> x` / `#=2> x` | stdout / stderr includes the String x, or matches the Regexp x |

A mistyped operator such as `#=X>` or `#=>>` is a failing expectation, and so is `##=>` (write `#=>`, or `# #=>` to comment one out). So is one missing its `=` (`#~> /x/`, `#!> Error`, `#:> String`), and `#>= 5`. With a space after the `#` a comparison is prose (`# >= 2.0`), and dividers (`# =====>`, `#------>`) are plain comments. One missing its `>` (`#== 5`, `#=~ /x/`) reads as a plain comment, so the test has no expectation: when a `##` test's code ends without one and holds such a comment, the parser warns `Test '...' has no expectation; its code runs as setup` (or an interlude, or teardown). The parser also warns about expectation-shaped comments inside a method or block body (they are not evaluated; a spaced `# => value` there is a doc comment and is not reported), expectations with no statement above them (each also fails as a test of its own), `#==> true`-style literals, and text after `#=*>`.

### Shared and fresh context

Shared context (the default) runs the file once as a single script. Fresh context (`--no-shared-context`) gives each test a new object and binding: the setup runs again, then every interlude above the test, then the test and its expectations, then the teardown. No local or instance variable one test sets is visible to another. Before the setup re-runs for the second and later tests, the top-level classes and constants the file defined are removed, so each test's setup defines them afresh (an `inherited` hook or a library registry sees every re-run; constants nested in an existing namespace stay). Nothing is removed after the last test, so they stay defined for the rest of the run, as in shared context; globals and reopened existing classes are not reset. A setup or interlude failure stops the file, including one that fails only when re-run for a later test; setup and teardown output and failures are reported once.

### Framework Translation

The core philosophy is using Tryouts as a preprocessor/transpiler:

- **RSpec Mode**: Generates `describe/it` blocks, leverages RSpec's full ecosystem
- **Minitest Mode**: Creates test classes with `test_*` methods
- **Direct Mode**: Original tryouts execution with shared context

This approach provides IDE support, debugging capabilities, and CI/CD integration through mature test frameworks.

`--rspec` and `--minitest` run each test's code once and judge every expectation with direct mode's own evaluators, so every operator means what it does in direct mode, and a mistyped or detached expectation is a failing example. RSpec runs the setup once before its examples and the teardown after them (`before(:all)`/`after(:all)`); Minitest runs them around every test (`setup`/`teardown`). Instance variables from the setup reach the tests, its local variables do not, and interludes run once, when the file is translated. `--generate-rspec` and `--generate-minitest` write standalone code: they translate `#=>`, `#==>`, `#=/=>`, `#=|>`, `#=:>`, `#=~>`, `#=*>` and `#=!>`, and emit a failing assertion that names the expectation for `#=<>`, `#=%>`, `#=1>`/`#=2>` and for mistyped or detached ones, so nothing is dropped.

### Test Organization

Test files are organized into logical directories:

- **`try/core/`** - Parsing, execution model, setup/teardown, shared and fresh context
- **`try/expectations/`** - All expectation types
- **`try/formatters/`** - Output formatting
- **`try/translators/`** - RSpec and Minitest translation
- **`try/regressions/`**, **`try/safety/`** - Regression and failure-handling cases
- **`try/continue-on-error/`** - Files that fail on purpose; expect failures when running them

Auto-discovers `*_try.rb` and `*.try.rb` files under `{app,apps,lib,try,tryouts}/` and in the current directory.
Files are processed in lexical order.

### Exit Codes
- `0`: All tests pass
- `1+`: Number of failing and erroring tests, plus one per setup, interlude or teardown failure in each file

### Key Dependencies
- **Ruby** (>= 3.2.0)
- **prism** (~> 1.0): Native Ruby parser
- **rspec**, **minitest**: Framework integration
- **rubocop**: Code quality with performance and thread safety extensions

## Things to AVOID
* Prematurely declaring the project is complete or production ready
* Backwards compatibility
