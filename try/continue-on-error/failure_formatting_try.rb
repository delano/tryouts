# try/formatters/failure_formatting_try.rb

## TEST: Regular expectation failure (the lists do not match)
[1, 2, 3]
#=> [4, 5, 6]

## TEST: Boolean true expectation failure (the list is NOT empty)
[1, 2, 3]
#==> result.empty?

## TEST: Boolean false expectation failure (the list IS empty)
[]
#=/=> result.empty?

## TEST: Result type failure (the return value is a String and not an Integer)
'hello'
#=:> Integer

## TEST: Performance timing failure (2ms is greater than 1ms)
sleep(0.02)
#=%> 1
