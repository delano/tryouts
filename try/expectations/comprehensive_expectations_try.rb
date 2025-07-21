# try/expectations/comprehensive_expectations_try.rb

## TEST: Regular expectation with clean expected display
[1, 2, 3]
#=> [1, 2, 3]

## TEST: Boolean true expectation
[1, 2, 3]
#==> result.length == 3

## TEST: Boolean false expectation
[1, 2, 3]
#=/=> result.empty?

## TEST: Boolean (true or false) expectation
true
#=|> result

## TEST: Result type expectation
"hello"
#=:> String

## TEST: Regex match expectation
"user@example.com"
#=~> /^[^@]+@[^@]+\.[^@]+$/

## TEST: Performance time expectation
1 + 1
#=%> 1

## TEST: Exception expectation
1 / 0
#=!> error.is_a?(ZeroDivisionError)

## TEST: Performance with timing expression
sleep(0.005)  # 5ms
#=%> result * 2
