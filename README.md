# Tryouts v2.3.0 (2024-04-04)

**Ruby tests that read like documentation.**

A simple test framework for Ruby code that uses introspection to allow defining checks in comments.

## Installation

One of:
* In your Gemfile: `gem 'tryouts'`
* As a gem: `gem install tryouts`
* From source:

```bash
  $ git clone git://github.com/tryouts/tryouts.git
```

## Usage

```bash
  # Run all tests accessible from the current directory (e.g. ./try, ./tryouts))
  $ try

  # Run a single test file
  $ try try/10_utils_try.rb

  # Command arguments
  $ try -h
  Usage: try [options]
      -V, --version                    Display the version
      -q, --quiet                      Run in quiet mode
      -v, --verbose                    Run in verbose mode
      -f, --fails                      Show only failing tryouts
      -D, --debug                      Run in debug mode
      -h, --help                       Display this help
```

### Exit codes

When all tests pass, try exits with a 0. An exit code of 1 or more indicates the number of failing tests.


## Writing tests

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

  ## The expectations are evaluated as well.
  81
  #=> 9 * 9

  ## Here's an example of testing errors
  begin
    raise RuntimeError
  rescue RuntimeError
    :success
  end
  #=> :success
```

For real world examples, see [Onetimesecret](https://github.com/onetimesecret/onetimesecret/) tryouts.


### Test setup / cleanup

Put the setup code at the top of the file, and cleanup code at the bottom. Like this:

```ruby
  # This is called before all tests
  require 'gibbler'
  Gibbler.digest_type = Digest::SHA256


  ## This is a single testcase
    :anything.gibbler
  #=> '8574309'


  # This will be called after all tests
  Gibbler.digest_type = Digest::SHA1
```

__


## Thanks

* [cloudhead](https://github.com/cloudhead)
* [mynyml](https://github.com/mynyml)
* [Syntenic](https://syntenic.com/) for the hackfest venue.
* [AlexPeuchert](https://www.rubypulse.com/) for the screencast.
* Christian Michon for suggesting a better default output format.

*This collision was brought to you by Montreal.rb.*
