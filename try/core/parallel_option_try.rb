# try/core/parallel_option_try.rb
#
# frozen_string_literal: true

# -j/--parallel takes an optional thread count. Only a number is a thread
# count, so the file paths after the option stay file paths, and the flags
# bundled with -j (-jv, -j4v) stay flags.

require_relative '../../lib/tryouts'

## A file after --parallel is a file to run, not a thread count
Tryouts::CLI.parse_args(%w[--parallel a_try.rb b_try.rb])
#=> [%w[a_try.rb b_try.rb], { parallel: true }]

## A file after -j is a file to run too
Tryouts::CLI.parse_args(%w[-j a_try.rb b_try.rb])
#=> [%w[a_try.rb b_try.rb], { parallel: true }]

## -j takes a number as the next word
Tryouts::CLI.parse_args(%w[-j 4 a_try.rb])
#=> [%w[a_try.rb], { parallel: true, parallel_threads: 4 }]

## -j takes a number attached to it
Tryouts::CLI.parse_args(%w[-j2 a_try.rb])
#=> [%w[a_try.rb], { parallel: true, parallel_threads: 2 }]

## --parallel takes a number after =
Tryouts::CLI.parse_args(%w[--parallel=3 a_try.rb])
#=> [%w[a_try.rb], { parallel: true, parallel_threads: 3 }]

## The option can also come after the files
Tryouts::CLI.parse_args(%w[a_try.rb b_try.rb --parallel])
#=> [%w[a_try.rb b_try.rb], { parallel: true }]

## Flags bundled after -j are flags, not a thread count
Tryouts::CLI.parse_args(%w[-jvf a_try.rb])
#=> [%w[a_try.rb], { parallel: true, verbose: true, fails_only: true }]

## A count attached to -j ends at its last digit, and the flags after it still apply
Tryouts::CLI.parse_args(%w[-j4v a_try.rb])
#=> [%w[a_try.rb], { parallel: true, parallel_threads: 4, verbose: true }]

## -j can still come last in a bundle, with its count
Tryouts::CLI.parse_args(%w[-vj4 a_try.rb])
#=> [%w[a_try.rb], { verbose: true, parallel: true, parallel_threads: 4 }]

## After -- a word that looks like a bundle is a file
Tryouts::CLI.parse_args(%w[-j -- -jv])
#=> [%w[-jv], { parallel: true }]
