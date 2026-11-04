# Tryouts - A Technical Guide for Agents

A concise guide for agentic LLMs on writing Tryouts tests:

**Core Structure**: A tryouts file is a Ruby script, run top to bottom. Statements before the first test are setup, statements after the last test are teardown, and each test is a `##` description, some code, and comment-based expectations.

**Syntax Rules**:
- A test case is a `##` description, Ruby code, and one or more expectations (`#=>` and friends) under its last statement
- An expectation checks the top-level statement directly above it, or the statement it trails on the same line (`1 + 1 #=> 2`)
- Multiple expectation types available (`#==>` for booleans, `#=:>` for types, `#=!>` for exceptions etc.)
- Local and instance variables persist from each statement to the next, across setup, tests and teardown
- Helper methods allowed in setup
- Use a single `# ` prefix for actual comments; a single `#` is never a description. DO NOT LABEL SECTIONS.

**Philosophy**: Code should be plain and realistic, avoiding test-specific patterns like mocks, asserts DSL.

Tryouts takes a documentation-first approach where tests demonstrate actual usage patterns rather than abstract test scenarios.

Full Guide below.

---

# Tryouts Framework Guide for Agentic LLMs

## Core Concept
Tryouts are Ruby tests that double as documentation. Use comment-based expectations (`#=>`) to verify results. Code should be plain and realistic, avoiding test-specific patterns like mocks.

## File Structure

A tryouts file is a Ruby script, executed top to bottom in one binding. It has three parts, none of them labelled:

```ruby
require 'json'
@defaults = { 'retries' => 3 }

## Defaults serialise to JSON
JSON.generate(@defaults)
#=> '{"retries":3}'

## Upcasing a string
'hello'.upcase
#=> 'HELLO'

@defaults.clear
```

- **Setup**: statements before the first test (`require`, `@defaults = ...`). Runs once.
- **Test cases**: each starts at a `##` description and ends at the statement its expectations sit under.
- **Teardown**: statements after the last test's expectations (`@defaults.clear`). Runs once.

## Test Case Structure

Each test case has 3 parts:
1. **Description**: Lines starting with `##`. `##` lines on adjacent lines join into one description, also across a bare `##` spacer line; a blank line or a plain `#` line ends the block. The text is kept as written.
2. **Code**: One or more Ruby statements
3. **Expectations**: One or more expectation comments in the gap after the last statement (the subject), or trailing it on the same line

```ruby
## Multiple expectations allowed
numbers = [1, 2, 3]
#=> [1, 2, 3]
#=> [1] + [2, 3]

## An expectation can trail the line it checks
numbers.sum #=> 6
```

`# =>` with a space means the same as `#=>`. Every test needs a `##` description; without one the parser rejects the file (strict mode, the default). `--no-strict` allows unnamed tests.

Code between one test's expectations and the next `##` description belongs to neither test. It runs in order, like setup, and the tests below it see what it did. If it raises, the rest of the file is skipped.

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

## Expectation Types

| Syntax | Purpose | Example |
|--------|---------|---------|
| `#=>` | Value equality (`==`) | `#=> 42` |
| `#==>` | Must be exactly true | `#==> result > 0` |
| `#=/=>` | Must be exactly false | `#=/=> result.empty?` |
| `#=\|>` | Must be true or false | `#=\|> result.any?` |
| `#=:>` | Is a kind of class or module | `#=:> String` |
| `#=~>` | Regex match against `result.to_s` (the exception message, if the test raised) | `#=~> /^\d+$/` |
| `#=!>` | Must raise; a class or module is checked with `is_a?`, any other expression must be truthy | `#=!> ZeroDivisionError` |
| `#=%>` | Ran within a limit in milliseconds (10% tolerance) | `#=%> 100` |
| `#=*>` | Not nil | `#=*>` |
| `#=<>` | Negation: a regex must not match, a true/false expression must be false, any other value must not be equal | `#=<> /error/` |
| `#=1>` | STDOUT includes the string or matches the regex | `#=1> 'Saved'` |
| `#=2>` | STDERR includes the string or matches the regex | `#=2> /warning/` |

Every expectation is a Ruby expression evaluated in the test's own binding. It can use the test's local and instance variables, and:
- `result` and `_`: the value of the subject, or the exception it raised when the test has a `#=!>`, `#=:>` or `#=~>` expectation (any other raise makes the test an error)
- `error`: the exception the test raised, or `nil`
- `elapsed_ms`: how long the test code took

A mistyped operator such as `#=x>` or `#=>>` always fails, and so does `##=>` (write `#=>` to assert, `# #=>` to comment it out). So does one missing its `=` (`#~> /x/`, `#!> KeyError`, `#:> String`, or `# >= 5` before a single value); prose such as `# >= 2 is plenty` and dividers of four or more `=` (`# =====>`) are comments. One missing its `>` (`#== 5`, `#=~ /x/`) is a plain comment, which leaves its test with no expectation: the parser warns `Test '...' at line N has no expectation; its code runs as setup` (or an interlude, or teardown), and nothing fails. An expectation directly under a `##` line, with no code between them, or before the first statement, does not apply to the test above; it fails as a test of its own. Each test has a 30-second deadline; a `Timeout::Error` raised by the test code is reported as itself. The parser warns about expectations that cannot fail (`#==> true`), text after `#=*>`, an expectation with no statement above it, and `#=>`-shaped or mistyped comments inside a method or block body (those are plain comments, not expectations).

## Exception Testing

```ruby
## The code must raise
Integer('forty-two')
#=!> ArgumentError
#=~> /invalid value/

## A condition on the exception
1 / 0
#=!> error.message.include?('divided')

## Rescue and test the result as a value
begin
  Integer('forty-two')
rescue ArgumentError => e
  e.class
end
#=> ArgumentError
```

`#=!>` runs the code once and checks what it raised. If nothing is raised, the test fails.

## Key Rules

1. **One subject per test case**: Expectations check the last statement of the test
2. **Variables persist**: Local and instance variables carry over from each statement to the next, across setup, tests and teardown (in the default shared context)
3. **Helper methods allowed**: Define in setup. The file runs at the top level like a script, but a top-level `def` is a method on the file's own main object, not on `Object`: top-level code and blocks can call it, a class the file defines cannot (pass the value in). Classes and constants the file defines are global and stay defined for the rest of the run, so later files see them (files run together under `-j`/`--parallel` share them too); give classes distinct names across files. Top-level `include` works; top-level `using` raises (use it inside a class or module body). Leading magic comments such as `# frozen_string_literal: true` apply to the whole file, also under `--rspec`/`--minitest`
4. **Comments ignored**: Only expectation comments (`#=>`, `#==>`, ...) after a top-level statement are expectations; `##` starts a description; anything else is a comment
5. **Blank lines OK**: Between code and expectations

## Common Patterns

```ruby
def greeting(name)
  "Hello, #{name}"
end

## Using helpers
greeting('Alice')
#=> 'Hello, Alice'

## Instance variables
@counter = (@counter || 0) + 1
@counter
#=> 1

## Local variables from earlier tests are still in scope
user = { name: 'Alice', age: 30 }
user[:name]
#=> 'Alice'

## The same local, one test later
user[:age] + 1
#=> 31
```

## Running Tests

```bash
# Auto-discover and run
try -vfD # verbose for failing tests, and enable debug mode (stack traces)

# Specific file
try -vfD path/to/file_try.rb path/to/dir

# Files in parallel (-j 4 or --parallel=4; --parallel 4 with a space reads 4 as a file)
try --agent -j 4 try/

# Flags bundled after -j stay flags: -jvf is -j -vf, -j4v is -j4 -v
try -jvf try/

```

## Anti-Patterns (Avoid)

- Mocks and test doubles
- Complex test harnesses
- Non-obvious test code
- Overly abstract helpers
- Test-specific data structures

Focus on readable, realistic Ruby code that demonstrates actual usage.

## Tryouts Execution Context Modes

See `docs/about-shared-or-fresh-context.md` for the full description.

**Shared Context (default)**

- The file is one script: setup, tests, code between tests, and teardown run once, in order, in one binding
- Local and instance variables persist from each statement to the next
- State accumulates - changes in test 1 affect test 2, etc.

**Fresh Context (`--no-shared-context`)**

- Each test gets a new object and binding
- Before each test, the setup runs again in it, then any code between earlier tests; after the test, the teardown
- Nothing is copied between bindings, so a mutable object from setup (`@items = []`) is a new object in every test
- Test isolation - changes in test 1 don't affect test 2, and a test cannot read locals an earlier test defined
- Before the setup re-runs for the second and later tests, the file's top-level classes and constants are removed, so class definitions run again (an `inherited` hook sees every run; constants nested in an existing namespace stay). Nothing is removed after the last test. A top-level `def` lands on the test's own object
- Globals, `ENV`, files on disk and changes to existing classes are not reset

In either mode, a setup or interlude failure stops the file: it fails, and the tests left are reported as not run (`2 not run, interlude failed` in the file's section, and in the SUMMARY counts).

`--rspec` and `--minitest` translate the file and use that framework's own setup and teardown hooks: RSpec runs the setup once before its examples, Minitest before every test. Each test's code runs once and every expectation is judged as in direct mode, and a mistyped or detached expectation fails. Instance variables from the setup reach the tests; its local variables do not. `--rspec` exits non-zero when an example fails.
