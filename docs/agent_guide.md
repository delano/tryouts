# Tryouts - A Technical Guide for Agents

A concise guide for agentic LLMs on writing Tryouts tests:

**Core Structure**: 3-section format (setup/testcases/teardown) with comment-based descriptions and expectations

**Syntax Rules**:
- Test cases are bookended with comments: prefix `##` for descriptions, Ruby code, and `#=>` expectations
- Multiple expectation types available (`#==>` for booleans, `#=:>` for types, `#=!>` for rescuing errors etc.)
- Instance variables persist across setup, tests, and teardown
- Helper methods allowed in setup
- Use a single `# ` prefix for actual comments. DO NOT LABEL SECTIONS.

**Philosophy**: Code should be plain and realistic, avoiding test-specific patterns like mocks, asserts DSL.

Tryouts takes a documentation-first approach where tests demonstrate actual usage patterns rather than abstract test scenarios.

Full Guide below.

---

# Tryouts Framework Guide for Agentic LLMs

## Core Concept
Tryouts are Ruby tests that double as documentation. Use comment-based expectations (`#=>`) to verify results. Code should be plain and realistic, avoiding test-specific patterns like mocks.

## File Structure

Every tryouts file has 3 sections:

```ruby
# SETUP SECTION (optional)
# Code runs once before all tests
puts 'Setup code'
@shared_variable = 'available to all tests'

## TEST CASE 1: Basic calculation
# Description lines start with ##
a = 1 + 1
#=> 2

## TEST CASE 2: String manipulation
'hello'.upcase
#=> 'HELLO'

# TEARDOWN SECTION (optional)
# Code runs once after all tests
puts 'Cleanup complete'
```

## Test Case Structure

Each test case has 3 parts:
1. **Description**: Lines starting with `##`
2. **Code**: Regular Ruby code
3. **Expectations**: One or more lines starting with `#=>`

```ruby
## TEST: Multiple expectations allowed
result = [1, 2, 3]
#=> [1, 2, 3]
#=> [1] + [2, 3]
```

## Expectation Types

| Syntax | Purpose | Example |
|--------|---------|---------|
| `#=>` | Value equality | `#=> 42` |
| `#==>` | Must be true | `#==> result > 0` |
| `#=/=>` | Must be false | `#=/=> result.empty?` |
| `#=:>` | Type check | `#=:> String` |
| `#=~>` | Regex match | `#=~> /^\d+$/` |
| `#=!>` | Exception handling | `#=!> error.is_a?(StandardError)` |
| `#=%>` | Performance (ms) | `#=%> 100` |

## Exception Testing

```ruby
## TEST: Exception handling
1 / 0
#=!> error.is_a?(ZeroDivisionError)

## TEST: Exception with rescue
begin
  raise "custom error"
rescue => e
  e.message
end
#=> "custom error"
```

## Key Rules

1. **One result per test case**: Last expression is the test result
2. **Instance variables persist**: `@var` available across setup, test cases, and teardown
3. **Helper methods allowed**: Define in setup section
4. **Comments ignored**: Only `#=>` lines are expectations
5. **Blank lines OK**: Between code and expectations

## Common Patterns

```ruby
# Setup helpers
def helper_method
  'I help with testing'
end

## TEST: Using helpers
helper_method
#=> 'I help with testing'

## TEST: Instance variables
@counter = (@counter || 0) + 1
@counter
#=> 1

## TEST: Complex objects
user = { name: 'Alice', age: 30 }
user[:name]
#=> 'Alice'
```

## Running Tests

```bash
# Auto-discover and run
try -vfD # verbose for failing tests, and enable debug mode (stack traces)

# Specific file
try -vfD path/to/file_try.rb path/to/dir

```

## Anti-Patterns (Avoid)

- Mocks and test doubles
- Complex test harnesses
- Non-obvious test code
- Overly abstract helpers
- Test-specific data structures

Focus on readable, realistic Ruby code that demonstrates actual usage.

## Tryouts Execution Context Modes

Shared Context (--shared-context or default in some modes)

- Setup runs once at file start
- All tests share the same container object
- Instance variables persist across all test cases
- State accumulates - changes in test 1 affect test 2, etc.

Fresh Context (default for most modes)

- Setup runs once at file start in a setup container
- Each test gets a new container object
- Instance variables from setup are copied to each fresh container
- Test isolation - changes in test 1 don't affect test 2
- BUT: Setup instance variables are inherited by all tests
