# Tryouts v2.2.0 (2024-04-04)

**Don't waste your time writing tests _and_ documentation!**


## Basic syntax

```ruby
  ## A very simple test
    1 + 1
  #=> 2

  ## The test description can spread
  ## across multiple lines. The same
  ## is true for test definitions.
    a = 'foo'
    b = 'bar'
    a + b
  #=> 'foobar'

  ## A test will pass when its return
  ## value equals the expectation.
    'foo'.class
  #=> String

  ## The expectations are evaluated.
    1 + 1
  #=> 1 + 1

  ## Here's an example of testing errors
    begin
      raise RuntimeError
    rescue RuntimeError
      :success
    end
  #=> :success
```

For real world examples, see [Gibbler](https://github.com/delano/gibbler/) tryouts.


## Setup / Cleanup

All code before the first test definition is assumed to be setup code. All code after the last definition is assumed to be cleanup code. Here is an example:

```ruby
  # This is called before all tests
  require 'gibbler'
  Gibbler.digest_type = Digest::SHA256

  ## A Symbol can gibbler
    :anything.gibbler
  #=> '754f87ca720ec256633a286d9270d68478850b2abd7b0ae65021cb769ae70c08'

  # This will be called after all tests
  Gibbler.digest_type = Digest::SHA1
```


## Running Tests

Try ships with a command-line tool called `try`. When called with no arguments, it will look for files ending with _try.rb in the current directory, or in the subfolder try.

You can also supply a specific file to test.

```ruby
  $ try path/2/test.rb
  Ruby 1.9.1 @ 2011-01-06 12:38:29 -0500

    # TEST 1: test matches result with expectation
  7    a = 1 + 1
  8    #=> 2
        ==  2
  ...

    ## TEST 12: comments, tests, and expectations can
    ## contain multiple lines
  13   a = 1
  14   b = 2
  15   a + b
  16   # => 3
  17   # => 2 + 1
        ==  3
        ==  3

    12 of 12 tests passed (and 5 skipped)
```

If all tests pass, try exits with a 0. Otherwise it exits with the number of tests that failed.


For reduced output, use the `-q` option:

```bash
    $ try -q
    Ruby 1.9.1 @ 2011-01-06 12:38:29 -0500

     42 of 42 tests passed (and 5 skipped)
      4 of 4 batches passed
```

__
## Installation

```bash
  $ gem install tryouts
```

Sure, here's how you could document the tree-sitter setup in a project's README.md file:

## Tree-sitter Integration

This project uses [tree-sitter](https://tree-sitter.github.io/tree-sitter/) for parsing and analyzing the source code. The tree-sitter-related files are located in the `tree-sitter` directory at the root of the project.

### Directory Structure

The tree-sitter files are organized as follows:

```
tryouts/
├── exe/
├── lib/
├── try/
├── tree-sitter/
│   ├── grammar/
│   ├── queries/
│   ├── tests/
│   └── bindings/
└── README.md
```

- `tree-sitter/grammar/`: This directory contains the tree-sitter grammar file(s) that define the syntax rules for the language(s) used in the project.
- `tree-sitter/queries/`: This directory stores the tree-sitter queries, which are used for semantic analysis of the source code.
- `tree-sitter/tests/`: This directory houses the tree-sitter test cases, which ensure the grammar and queries are working as expected.
- `tree-sitter/bindings/`: If the project generates language-specific tree-sitter bindings, they would be located in this directory.

### Running Tree-sitter Commands

When running tree-sitter commands, you'll need to provide the appropriate paths to the files and directories within the `tree-sitter` directory.

For example, to generate the parser from the grammar file:

```
cd tree-sitter
tree-sitter generate grammar/grammar.js
```

To build the parser:

```
tree-sitter build

# OR, to run the playground

tree-sitter build --wasm
```

And to run the tests:

```
tree-sitter test
```
Use `-u` to update the snapshots in the test/corpus/*.txt files (the sexpr after the "---" for each test).

To run the parser on a specific file:

```
tree-sitter parse ../try/step0_try.rb
```

Use `--stat` to print stats; `--dot` to generate a graphviz log.html file; `--time` to print timing info.

By separating the tree-sitter-related files and commands, we can keep our project structure clean and make it easier to manage the tree-sitter integration within our overall build and testing workflows.


## Thanks

* [cloudhead](https://github.com/cloudhead)
* [mynyml](https://github.com/mynyml)
* [Syntenic](https://syntenic.com/) for the hackfest venue.
* [AlexPeuchert](https://www.rubypulse.com/) for the screencast.
* Christian Michon for suggesting a better default output format.

*This collision was originally brought to you by Montreal.rb.*
