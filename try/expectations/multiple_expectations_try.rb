# try/expectations/multiple_expectations_try.rb

## TEST1: Returns an array, has multiple expectations
[1, 2, 3]
#=> [1, 2, 3]
#==> result.class == Array
#==> result.size == 3
#==> result.length > 2

## TEST2: Boolean true expectations work correctly
[1, 2, 3]
#==> result.length == 3  # must evaluate to true
#==> result.include?(2)  # must evaluate to true
#==> result.any? { |x| x > 2 }  # must evaluate to true

## TEST3: Boolean false expectations work correctly
[1, 2, 3]
#=/=> result.empty?  # must evaluate to false
#=/=> result.include?(5)  # must evaluate to false
#=/=> result.all? { |x| x > 10 }  # must evaluate to false

## TEST4: Exception expectations with new syntax
1 / 0  # This should raise ZeroDivisionError
#=!> error.is_a?(ZeroDivisionError)  # must raise an error

## TEST5: Complex boolean expressions with local vars
numbers = (1..10).to_a
#==> _.include?(5) && result.length == 10 # must evaluate to true
#=/=> result.all? { |n| n.is_a?(Float) } # must evaluate to false
#==> result.first == 1
numbers  # Return numbers so it's available as 'result'

## TEST6: Boolean evaluator (true OR false)
true
#=|> result  # Must be true or false

## TEST7: Boolean evaluator with false value
false
#=|> result  # Must be true or false
