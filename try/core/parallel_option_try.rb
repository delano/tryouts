# try/core/parallel_option_try.rb
#
# frozen_string_literal: true

# -j/--parallel takes an optional thread count. Only a number is a thread
# count, so the file paths after the option stay file paths.

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
