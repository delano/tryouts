# try/core/heredoc_statements_try.rb
#
# frozen_string_literal: true

# A heredoc body lies below the line that opens it, so a statement written
# after the opener on that line comes before the body in the source. The two
# statements run once, together, and the expectation trailing the line
# asserts on the last of them.

## Two heredocs opened on one line each keep their own body
greeting = <<~HELLO; farewell = <<~BYE #=> "goodbye\n"
  hello
HELLO
  goodbye
BYE
#==> greeting == "hello\n"

## Both heredocs are assigned when they share an opener line
first, second = <<~ONE, <<~TWO
  one
ONE
  two
TWO
[first, second]
#=> ["one\n", "two\n"]

## A statement on a heredoc's opener line runs with the heredoc
$banner_views = 0
banner = <<~TEXT; $banner_views += 1 #=> 1
  welcome
TEXT

## and runs only once
$banner_views
#=> 1

## The trailing expectation asserts on the statement after the heredoc
template = <<~SQL; template.lines.size #=> 2
  SELECT name
  FROM users
SQL
