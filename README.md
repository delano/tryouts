# Tryouts - A Ruby Testing Framework

**Ruby tests that read like documentation.**

A modern Ruby testing framework that uses simple comments to define what should happen. With Tryouts, your tests double as documentation, allowing you to write straightforward Ruby code that feels as natural as everyday coding.

> [!NOTE]
> **Agent-Optimized Output**: Tryouts includes specialized output modes for LLM consumption with `--agent` flag, providing structured, token-efficient test results that are 60-80% smaller than traditional output while preserving debugging context.

> [!WARNING]
> Version 3.0+ uses Ruby's Prism parser and pattern matching, requiring Ruby 3.2+

## Key Features

- **Documentation-style tests** using comment-based expectations (`#=>`), on the line below or trailing the code (`1 + 1 #=> 2`)
- **Great expectation syntax** for more expressive assertions (`#==>` for true, `#=/=>` for false, `#=:>` for class/module)
- **Framework integration** write with tryouts syntax, run with RSpec or Minitest
- **Agent-optimized output** structured, token-efficient output for LLM consumption
- **Enhanced error reporting** with line numbers and context

## How a file runs

A tryouts file is a Ruby script. It is executed top to bottom in one binding. Local and instance variables persist from each line to the next. An expectation comment asserts something about the value of the statement immediately above it, or the statement it trails on the same line. A `##` comment names the group of statements that ends at the next expectation, for reporting only.

As in a script, the file runs at the top level: `class Widget` defines `::Widget`, and a top-level `include` mixes into `Object`. A top-level `def` defines a method on the file's own main object, not on `Object`. Top-level code and the blocks in it can call that method, but a class the file defines cannot, so pass the value in or make the helper a class or module method. Classes and constants the file defines are global and stay defined for the rest of the run, as they would if Ruby loaded several files into one process (RSpec and Minitest behave the same): the next file sees `Widget`, and a second `class Widget` reopens it, or raises superclass mismatch if it names another superclass. Files run together with `-j`/`--parallel` share them as they run. Give the classes in different files distinct names. Changes to existing classes, such as reopening `String`, are not undone. Top-level `using` raises, because each section is evaluated on its own and a refinement could not reach the code after it; call `using` inside a class or module body instead. Magic comments at the top of the file, such as `# frozen_string_literal: true`, apply to every section and expectation, also under `--rspec` and `--minitest`.

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

Tryouts use a comment-based syntax for expectations:

```ruby
# Setup code runs before all tests
require 'json'
config = { 'name' => 'tryouts', 'tags' => %w[ruby testing] }

## Simple test with expectation
a = 1 + 1
#=> 2

## An expectation can trail the line it checks
'hello'.upcase #=> 'HELLO'

## Several statements make up one test;
## the last one is the subject
a = 1
b = 2
a + b
#=> 3

## Locals from setup and earlier tests are still in scope
[config['name'], a]
#=> ['tryouts', 1]

## Expressions are evaluated
81
#=> 9 * 9

## One subject can have several expectations
JSON.generate(config)
#=:> String
#=~> /"tags":\["ruby","testing"\]/
#==> result.start_with?('{')

## Testing errors with rescue
begin
  Integer('forty-two')
rescue ArgumentError
  :caught
end
#=> :caught

## Testing that the code raises
Integer('forty-two')
#=!> ArgumentError
#=~> /invalid value/

# Teardown runs after all tests
config.clear
```

### Test Structure

Each test file is made up of three sections:
- **Setup**: Code before the first test case
- **Test Cases**: A description (`##`), Ruby code, and expectations (`#=>`)
- **Teardown**: Code after the last test case's expectations

A test case is the run of statements from its `##` description down to the statement its expectations sit under (the subject). The value of the subject is `result`. `##` lines on adjacent lines join into one description, and the text is kept as written; a blank line or a plain `#` line ends the block, so a `##` heading above it is just a comment. A bare `##` with no text is a plain comment. A single `#` is always an ordinary comment, so prose in setup or between tests never turns into a test.

An expectation goes in the gap after its subject, or at the end of the subject's last line. `# =>` with a space is the same as `#=>`, which is how IRB transcripts and Ruby docs write it.

Code between one test's expectations and the next `##` description is not part of either test. It runs in order, like setup, and anything it defines is visible to the tests below it. If it raises, the rest of the file is skipped: the file fails, and the tests that did not run are counted as not run (`1/3 passed, 2 not run, interlude failed`). A failure in setup does the same.

```ruby
## Starts empty
@cache = {}
@cache.size
#=> 0

@cache[:user] = 'alice'

## Sees the line above
@cache.fetch(:user)
#=> 'alice'
```

By default (strict mode) every test needs a `##` description; `--no-strict` allows unnamed ones. A mistyped operator such as `#=x>` or `#=>>` fails rather than being skipped, and so does `##=>`: write `#=>` to assert, or `# #=>` to comment an expectation out. An operator missing its `=` fails too: `#~> /x/`, `#!> KeyError`, `#:> String`, and `#>= 5` or `# >= 5` when a single Ruby value follows it (`# >= 2 items is plenty` is prose, a comment). A divider such as `# =====>`, four or more `=` in a row, is a comment. An operator missing its `>`, such as `#== 5` or `#=~ /x/`, reads as a plain comment, which leaves its test without an expectation; the parser warns when a `##` test's code holds such a comment and no expectation (`Test 'Sum' at line 8 has no expectation; its code runs as an interlude`). The parser also warns about `#=>`-shaped (or mistyped) comments inside a method or block body, expectations that can never fail, such as `#==> true`, and expectations it cannot attach to anything. An expectation with no statement above it in its own test (before the first statement, or directly under a `##` line) does not apply to the test above: the parser warns about it, and it fails as a test of its own.

Each test has a 30-second deadline; a test that runs past it is reported as an error. A `Timeout::Error` raised by the code under test is reported as itself, so `#=!> Timeout::Error` works.

### Great Expectations System

  | Syntax | Description                | Example                             | Context       |
  |--------|----------------------------|-------------------------------------|---------------|
  | `#=>`  | Traditional value equality (`==`) | `#=> [1, 2, 3]`                     | result, _     |
  | `#==>` | Must be exactly true       | `#==> result.include?(2)`            | result, _     |
  | `#=/=>`| Must be exactly false      | `#=/=> _.empty?`                     | result, _     |
  | `#=\|>` | Must be true OR false     | `#=\|> result.any?`                  | result, _     |
  | `#=!>` | Must raise; fails if nothing is raised. A class or module is checked with `is_a?`, anything else must be truthy | `#=!> ZeroDivisionError` or `#=!> error.message.include?('divided')` | error         |
  | `#=:>` | Must be a kind of the class or module | `#=:> String`                         | result, _     |
  | `#=~>` | Must match regex pattern (`result.to_s`, or the exception message if the test raised) | `#=~> /^[^@]+@[^@]+\.[^@]+$/`         | result, _     |
  | `#=%>` | Must complete within a limit in milliseconds, with 10% tolerance | `#=%> 2000`         | elapsed_ms    |
  | `#=*>` | Must be non-nil            | `#=*>`                                | result, _     |
  | `#=1>` | STDOUT contains the string or matches the regex | `#=1> "You have great success"`       | stdout        |
  | `#=2>` | STDERR contains the string or matches the regex | `#=2> /request-id \d{1,5}/`        | stderr        |
  | `#=<>` | Must NOT hold: a regex must not match, a true/false predicate must be false, any other value must not be equal | `#=<> result.include?(4)`            | result, _     |

Every expression runs in the test's own binding, so it can use the test's local variables as well as `result` and `_` (the subject's value), `error` (the exception it raised, or `nil`) and `elapsed_ms` (how long the test took). In `#=%>`, `result` is still the value; the measurement is `elapsed_ms`. `#=!>` never re-runs the code: the test runs once and the exception it raised is checked. Text after `#=*>` is ignored, with a warning.

### Shared and fresh context

By default a file runs in one shared binding, as described in [How a file runs](#how-a-file-runs). With `--no-shared-context` each test gets its own: a new object and binding, into which the setup is re-run, then any code between earlier tests, then the test and its expectations, then the teardown. No local or instance variable leaks from one test into another. A top-level `def` lands on the test's own object. Before the setup re-runs for the second and later tests, the top-level classes and constants the file defined are removed, so `class Point < Struct.new(:x, :y)` is defined afresh for each test; an `inherited` hook or a library's registry sees each re-run, and constants the file nests in an existing namespace (`JSON::Point`) are not removed. Nothing is removed after the last test. Globals and changes to existing classes are not reset. But a test can no longer read a local that an earlier test defined (`a` in the "Locals from setup" example above would be a `NameError`). Setup and teardown output and failures are reported once, not per test. A failure in setup or in code between tests stops the file, including one that only fails when re-run for a later test.

```bash
try --no-shared-context try/core/basic_syntax_try.rb
```

### Using other test runners

Version 3 introduces framework translators that convert tryouts into the equivalent tests in popular test tools, like RSpec and Minitest.

`--rspec` and `--minitest` run each test's code once and judge its expectations with the same evaluators as direct mode, so every operator means the same thing, and a mistyped or detached expectation is a failing test. `--rspec` exits non-zero when an example fails. RSpec runs the setup once before the examples and the teardown after them; Minitest runs them around every test. Instance variables from the setup reach the tests; its local variables do not. The generated code (`--generate-*`) is standalone: it translates `#=>`, `#==>`, `#=/=>`, `#=|>`, `#=:>`, `#=~>`, `#=*>` and `#=!>`, and writes a failing assertion that names the expectation for `#=<>`, `#=%>`, `#=1>`/`#=2>` and for mistyped or detached ones, rather than dropping them.

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
try --inspect             # show how a file is split into setup, tests and teardown
try --no-strict           # allow tests without a ## description
try --no-shared-context   # run each test in its own fresh binding
try -j 4 try/             # run files in parallel on 4 threads (or --parallel=4; -j alone uses one per CPU)
try -jvf try/             # flags bundled after -j are flags: -j -vf

# Agent-optimized output for LLMs
try --agent                              # structured, token-efficient output
try --agent --agent-focus summary        # show only counts and problem files
try --agent --agent-focus first-failure  # show first failure per file
try --agent --agent-focus critical       # show only errors/exceptions
try --agent --agent-limit 1000          # limit output to 1000 tokens
```

#### Why Not Pipe Test Output Directly to AI?

I mean, you could. If that already works well, you could probably still benefit from an agent that is able to focus on the critical information for the task. And the extra context window space.

Raw test output creates problems when working with AI assistants: high token usage with inconsistent parsing across different runs, where the same logical failure might be interpreted differently, making it difficult to reliably produce and analyze results consistently.

#### TOPAZ: A Better Approach

Tryouts' `--agent` mode inspired the development of **TOPAZ (Test Output Protocol for AI Zealots)** - a standardized format optimized for AI analysis. The [tpane](https://github.com/delano/tpane) tool implements this protocol, transforming any test framework's output into structured, token-efficient formats.

Instead of overwhelming AI with raw output, TOPAZ provides clean semantic data focusing on what actually needs attention - failures, errors, and actionable context.

### Exit Codes

- `0`: All tests pass
- `1+`: Number of failing and erroring tests, plus one for each setup, interlude or teardown failure in a file


## Requirements

- **Ruby >= 3.2** (for Prism parser and pattern matching)
- **RSpec** or **Minitest** (optional, for framework integration)

## Modern Architecture (v3+)

### Core Components

- **Prism Parser**: Native Ruby parsing; each comment is attached to the top-level statement it follows or trails
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

- **Claude Sonnet 4, Opus 4.1** - Architecture design, code generation, and documentation
- **Claude Desktop & Claude Code (Max plan)** - Interactive development sessions and debugging
- **GitHub Copilot** - Code completion and refactoring assistance
- **Qodo Merge Pro** - Code review and quality improvements

I remain responsible for all design decisions and the final code. I believe in being transparent about development tools, especially as AI becomes more integrated into our workflows as developers.
