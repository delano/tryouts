# try/README.md
---
# Tryouts Test Organization

This directory contains the test suite for Tryouts v3.0, organized by functionality. The suite is written in tryouts, so it doubles as a reference for the syntax.

## Running Tests

```bash
# All tests
try

# By directory or file
try try/core/
try try/core/advanced_syntax_try.rb

# Noise, more or less
try -v  # verbose mode includes the source code, expected and actual output
try -vf # verbose, only for failed tests
try -q  # quiet mode, just dots and end result
try -q  2> /dev/null # if you only care about the exit code

# Structure and context
try --inspect try/core/script_model_try.rb  # show what the parser found, without running
try --no-shared-context try/core/           # fresh context: isolate every test
try --no-strict path/to/file_try.rb         # allow expectations without a ## description
```

`try/continue-on-error/` holds files that fail on purpose. Expect failures when you run it.

To integrate with existing CI workflows or for old school homies, run the tests as rspec or minitest.

```bash
try --rspec
try --minitest

# Or generate the test files for later
try --generate-rspec try/core/basic_syntax_try.rb > spec/basic_syntax_spec.rb
try --generate-minitest try/core/basic_syntax_try.rb > test/basic_syntax_test.rb
```

## How a Tryouts File Runs

A tryouts file is a Ruby script. It runs top to bottom in one binding, so local and instance variables persist from each statement to the next. An expectation comment asserts on the value of the top-level statement above it, or of the statement it trails on the same line. A `##` comment names the test case that ends at that expectation.

- **Setup**: statements before the first test case.
- **Test case**: a `##` description, the statements after it, and the expectations under the last one. That last statement is the subject; its value is `result`.
- **Interlude**: statements between one test's expectations and the next `##`. They run in order before the next test. If one raises, the file stops.
- **Teardown**: statements after the last expectation.

This file is written for shared context; its second and third tests depend on state left by the code above them.

```ruby
require 'set'

visited = Set.new
@log    = []

## Setup locals and instance variables are visible to tests
visited << '/home'
@log << 'GET /home'
[visited.size, @log.size]
#=> [1, 1]

## In shared context, state carries into later tests
visited.include?('/home')
#=> true

visited << '/about'

## The interlude above ran before this test
visited.size
#=> 2

## TEST: a description keeps its text as written
2 + 2
# => 4
```

Some details that follow from the model:

- Consecutive `##` lines join into one description, with a space. `## TEST: x` is described as "TEST: x".
- A single `#` is always a plain comment. `# TEST:` does not name a test.
- `# =>` with a space is the same as `#=>`.
- In strict mode (the default), an expectation without a `##` description above it is an error. `--no-strict` allows it.
- An expectation-shaped comment inside a method, class or block body is not evaluated; the parser warns about it.

## Expectations

Each test case can have several expectations, and all must pass. Inside an expectation, `result` (or `_`) is the test's value, `error` is the exception the test raised (or nil), and `elapsed_ms` is how long the test code took. The expression runs in the test's binding, so it sees the test's local and instance variables.

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

```ruby
## #=> compares with ==
[1, 2, 3].map { |n| n * 2 }
#=> [2, 4, 6]

## #==> must be exactly true, #=/=> exactly false, #=|> either
'tryouts'
#==> result.start_with?('try')
#=/=> result.empty?
#=|> result.frozen?

## #=:> checks is_a?
{ name: 'Ada' }
#=:> Hash
#=:> Enumerable

## #=~> matches against result.to_s
Time.at(0).utc.year
#=~> /\A1970\z/

## #=!> passes only when the test code raises
Integer('ten')
#=!> ArgumentError
#=~> /invalid value/

## #=!> also takes a true-or-false expression about error
Hash.new.fetch(:missing)
#=!> error.is_a?(KeyError) && error.key == :missing

## #=<> with a value: must not equal
[3, 1, 2].sort
#=<> [3, 1, 2]

## #=<> with a Regexp: must not match
'order-1042'
#=<> /\s/

## #=<> with a true-or-false expression: must be false
[1, 2, 3]
#=<> result.empty?

## #=%> sets a time limit in milliseconds
(1..1_000).sum
#=%> 50
#==> elapsed_ms < 50

## #=*> passes for anything except nil
ENV.fetch('HOME', '/root')
#=*>

## #=1> and #=2> check stdout and stderr
puts 'saved 3 records'
warn 'disk is 91% full'
#=1> 'saved 3 records'
#=2> /\d+% full/
```

`#=!>` needs the test code itself to raise. `lambda { raise 'boom' }` is a value, not a raise, so `#=!>` under it fails.

The parser warns about:

- a mistyped operator such as `#=X>` (the expectation always fails)
- an expectation inside a statement body (not evaluated)
- an expectation with no statement above it
- `#==> true` and similar literals, which test nothing about the result
- text after `#=*>`, which is ignored
- an expectation without a `##` description (an error in strict mode)

## Shared and Fresh Context

Shared context (the default) runs the file once as a single script, as described above. Fresh context (`--no-shared-context`) gives each test its own object and binding. Before each test the setup runs again, then every interlude above the test; then the test and its expectations run, then the teardown. Nothing one test does is visible to any other. A setup or interlude failure stops the file, and setup and teardown output and failures are reported once.

This file passes in fresh context and fails in shared context:

```ruby
@cart = [:setup]

## Each test starts from a freshly run setup
@cart << :apple
@cart
#=> [:setup, :apple]

@cart << :interlude

## Earlier tests leave nothing behind, and the interlude above runs again
@cart
#=> [:setup, :interlude]
```

## Test Content Guidelines

- Tests should read like documentation
- Use descriptive `##` test case descriptions; use single `#` comments for prose, not to label sections
- Group related functionality within files
- Avoid test framework specific code (mocks, harnesses)
- Know your expectation types and their behaviour. All testcases are not created equally.
- Follow the pattern `*_try.rb` (or `*.try.rb`) to be automatically discovered by the Tryouts framework.
