# doc/test_failing.rb

# Running: ./exe/try doc/test_failing.rb try/proof1_try.rb

## Test failure example
1 + 1
#=> 3

## Another failing test
'hello'.upcase
#=> "GOODBYE"

## Divide by 0
1/0
#=> ZeroDivisionError: divided by 0

## Manually raise a stack level too deep
raise SystemStackError.new('Manually created this SystemStackError for testing')
#=> SystemStackError: Manually created this SystemStackError for testing

## Raise a load error
raise LoadError.new('Manually created this LoadError for testing')
#=> LoadError: Manually created this
