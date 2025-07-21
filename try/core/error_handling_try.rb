# try/core/error_handling_try.rb
# Tests for error handling and deliberate failures

## Test failure example (intentional failure)
1 + 1
#=<> 3

## Another failing test (intentional failure)
'hello'.upcase
##=> "GOODBYE"

## Divide by zero exception test
1/0
#=!> error.is_a?(ZeroDivisionError)

## Manually raise a stack level too deep
raise SystemStackError.new('Manually created this SystemStackError for testing')
#=!> error.is_a?(SystemStackError)

## Raise a load error
raise LoadError.new('Manually created this LoadError for testing')
#=!> error.is_a?(LoadError)
