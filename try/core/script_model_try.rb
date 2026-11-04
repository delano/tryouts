# try/core/script_model_try.rb
#
# frozen_string_literal: true

# A tryouts file is a Ruby script. It runs top to bottom in one binding, so
# local and instance variables persist from each statement to the next. An
# expectation comment asserts on the value of the statement above it, or of
# the statement it trails on the same line.

greeting = 'hello'
@visits  = 0

## TEST: Setup locals are visible to tests
greeting.upcase
#=> 'HELLO'

## TEST: An expectation can trail its statement on the same line
[1, 2, 3].sum #=> 6

## TEST: Expectations see the test's own local variables
total = [1, 2, 3].sum
total * 2
#=> total + total

## TEST: Instance variables persist between tests
@visits += 1
@visits
#=> 1

## TEST: Local variables persist between tests too
greeting + ' again'
#=> 'hello again'

## TEST: result is this test's value even when it is nil
nil
#==> result.nil?

## TEST: error is only bound in a test that raised
raise ArgumentError, 'boom'
#=!> ArgumentError
#==> error.message == 'boom'

## TEST: error is nil in the next test
:no_error
#==> error.nil?

## TEST: The value of a multi-line statement is its subject
if greeting.start_with?('h')
  :starts_with_h
end
#=> :starts_with_h

## TEST: A heredoc statement keeps its whole body
<<~TEXT.lines.size
  first
  second
TEXT
#=> 2

## TEST: The executor's own locals are not visible in the binding
binding.local_variables.sort
#=> [:greeting, :total]
