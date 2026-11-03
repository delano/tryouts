# Shared and fresh context

Tryouts can run a file in one of two ways. Shared context, the default, runs the file as the Ruby script it looks like. Fresh context (`--no-shared-context`) runs each test on its own, with the file's setup in front of it and its teardown after it.

Both modes parse the file the same way. A file is a list of top-level statements, cut into these parts:

- **Setup**: the statements before the first test.
- **Test cases**: a `##` description, the statements below it, and the expectations under the last of those statements (the subject).
- **Interludes**: statements between one test's subject and the next test's `##` description. They belong to neither test.
- **Teardown**: the statements after the last test's subject.

The two modes differ only in which binding each part runs in, and how often.

## Shared context: the file is one script

A tryouts file is a Ruby script. It is executed top to bottom in one binding. Local and instance variables persist from each statement to the next, across setup, tests, interludes and teardown. An expectation asserts something about the value of the statement above it, and is evaluated in the same binding, so it can use the same locals.

```ruby
require 'json'

settings = { 'retries' => 3 }

## Settings serialise to JSON
json = JSON.generate(settings)
#=> '{"retries":3}'

## The JSON reads back as the same hash
JSON.parse(json)
#=> settings

settings['retries'] = 5

## Code between tests has already run when the next test starts
settings['retries']
#=> 5

settings.clear
```

Everything runs once, in source order: the setup (`require`, `settings = ...`), the first test, the second test (which reads the `json` local the first test defined), the interlude (`settings['retries'] = 5`), the third test, then the teardown.

What follows from this:

- Test order matters. A test sees whatever the statements above it left behind, including what earlier tests changed.
- A test that raises an unexpected exception is reported as an error and the file carries on. The statements it ran before the raise have still run, so later tests see their effects.
- If the setup or an interlude raises, the rest of the file is skipped: every test below it would be running against state that never got built. A teardown failure is reported and the file still counts its results.
- The binding's `self` is a plain `Object` created for the file. A top-level `def` defines a method on that object, and `class Report` defines a constant under it, so two files can each define their own `Report` without clashing. No local variable from the runner itself is visible to the file.

Use shared context for files that read as a walkthrough, where each example builds on the one before. That is the documentation style tryouts is designed for.

## Fresh context: each test on its own

```bash
try --no-shared-context path/to/file_try.rb
```

For each test, fresh context:

1. creates a new `Object` and a new binding on it;
2. runs the setup in that binding;
3. runs every interlude above the test, in order;
4. runs the test and evaluates its expectations;
5. runs the teardown in the same binding.

The binding is then thrown away. This is the per-test `setup`/`teardown` model of Minitest, or `before(:each)`/`after(:each)` in RSpec: each test sees the state it would see if it were the only test in the file.

Nothing is copied from one binding to another. The setup is run again rather than its results reused, so a mutable object it creates (an array, a hash, a connection) is a new object for every test. A test cannot change it for the next one.

```ruby
@cart = []
discount = 0

## Adding an item
@cart << 'apple'
discount = 10
@cart.size
#=> 1

## The setup ran again: the cart is empty and the discount is back to 0
[@cart, discount]
#=> [[], 0]

@cart << 'bread'

## Code between earlier tests runs again before this one
@cart
#=> ['bread']

## And before every test after it
@cart.first
#=> 'bread'

@cart.clear
```

All four tests pass in fresh context. In shared context the last three fail, because the first test's `'apple'` and `discount = 10` are still there.

What follows from this:

- A test cannot read a local or instance variable that an earlier test defined. In the shared-context example above, the second test's `JSON.parse(json)` raises `NameError` in fresh context, because `json` was defined by the first test.
- The setup, the interludes above a test and the teardown run once per test. Keep them cheap; a file with 50 tests and a slow setup is 50 times slower in fresh context.
- Setup, interlude and teardown output is shown once, the first time it runs, not once per test. A failure in any of them is also reported once.
- If the setup or an interlude raises, the rest of the file is skipped, as in shared context.
- The teardown runs after every test, including one that raised.

### What fresh context does not reset

Fresh context isolates the binding: its `self` and its local and instance variables. It does not undo changes the code makes to the rest of the process:

- classes, modules, constants and methods the file defines: the file runs at the top level, as a script does, so `class Widget` is `::Widget` and a re-run setup assigns its constants again;
- global variables (`$count`), `ENV`, and files on disk;
- `require`: a library is loaded once per process, so a second `require` in the next test's setup is a no-op;
- changes to existing classes, such as `class String` or `String.include(SomeModule)`;
- class-level state in library code, such as a cache or a configuration object held in a constant.

A test that changes one of these changes it for every test after it, in either mode. If a test needs to change global state, put it back in the teardown.

## Choosing a mode

- Shared context suits documentation-style files: an example sets something up, the next example uses it. It is also the fastest, since everything runs once.
- Fresh context suits files of independent unit tests, and checks that they really are independent. A file that passes in both modes does not depend on the order of its tests or on what one test leaves for the next.

To make a file work in both modes, put everything a test needs either in the setup, in an interlude above it, or in the test itself, and never rely on a value an earlier test created.

## RSpec and Minitest

`--rspec` and `--minitest` do not use either mode. They translate the file into that framework's own structure and its own setup and teardown hooks; see `lib/tryouts/translators/`.
