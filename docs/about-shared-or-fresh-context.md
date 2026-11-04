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
- If the setup or an interlude raises, the rest of the file is skipped: every test below it would be running against state that never got built. The file fails, and the tests it skipped are reported as not run (`1/3 passed, 2 not run, interlude failed`). A teardown failure is reported and the file still counts its results.
- The binding's `self` is a new object created for the file, which prints as `main`, with no local variables from the runner. Code runs at the top level, as in a script: `class Report` defines `::Report`, and a top-level `include` mixes into `Object`.
- A top-level `def` defines a public method on that object, not on `Object`. Top-level code and the blocks in it can call it; a method of a class the file defines cannot, as it could in a plain script, so pass the value in or make the helper a class or module method.
- Classes and constants the file defines are global: any code can see `Report`. They stay defined for the rest of the run, as they would if Ruby loaded several files into one process (RSpec and Minitest behave the same). A later file sees `Report`; its own `class Report` reopens it, or raises superclass mismatch if it names a different superclass. Files run together with `-j`/`--parallel` share them as they run. Give the classes in different files distinct names. Reopening an existing class, such as `class String`, is not undone.
- Top-level `using` raises, because each section is evaluated on its own and the refinement could not reach later code; use `using` inside a class or module body.
- Magic comments at the top of the file, such as `# frozen_string_literal: true`, apply to the setup, every test and interlude, the teardown and every expectation. They apply under `--rspec` and `--minitest` too.

Use shared context for files that read as a walkthrough, where each example builds on the one before. That is the documentation style tryouts is designed for.

## Fresh context: each test on its own

```bash
try --no-shared-context path/to/file_try.rb
```

For each test, fresh context:

1. creates a new object and a new binding on it, as shared context does for the whole file;
2. for the second and later tests, removes the top-level classes and constants the file defined;
3. runs the setup in that binding;
4. runs every interlude above the test, in order;
5. runs the test and evaluates its expectations;
6. runs the teardown in the same binding.

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
- Setup, interlude and teardown output is shown once, the first time it runs, not once per test. The setup is announced before the first test and the teardown after the last, as in shared context. A failure in any of them is reported once, on whichever run it happens.
- If the setup or an interlude raises, the rest of the file is skipped and those tests are reported as not run, as in shared context. That includes a setup or interlude that passed for earlier tests and fails when run again for a later one (for example, one that creates a directory); the report names the test it was preparing.
- The teardown runs after every test, including one that raised.

### What fresh context does not reset

Fresh context isolates the binding: its `self`, its local and instance variables and the methods a top-level `def` puts on it. Before it re-runs the setup for the second and later tests, it also removes the classes, modules and constants the file defined at the top level, so the setup defines them again: `class Point < Struct.new(:x, :y)` gets a new superclass every time without a superclass mismatch. After the last test nothing is removed, so they stay defined for the rest of the run, as in shared context. Running the class definitions again has consequences of its own:

- a constant the file nests inside an existing namespace, such as `JSON::Point` or a constant inside a library's module, is not removed;
- each run defines new class objects, so an `inherited` hook or a registry kept by a library class sees every run.

It does not undo other changes the code makes to the rest of the process:

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

`--rspec` and `--minitest` do not use either mode. They translate the file into that framework's own structure and its own setup and teardown hooks; see `lib/tryouts/translators/`. RSpec runs the setup once, before its examples (`before(:all)`), and the teardown after them; Minitest runs them around every test. Instance variables the setup sets reach the tests; its local variables do not, so a file that reads a setup local in a test fails there. Each test's code runs once and its expectations are judged by the same evaluators as in direct mode, so every operator means the same thing, and a mistyped or detached expectation is a failing test. Constants the file defines stay defined, as in direct mode.
