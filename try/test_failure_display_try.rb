# try/test_failure_display_try.rb

## TEST: Regular expectation failure
[1, 2, 3]
#=> [4, 5, 6]

## TEST: Boolean true expectation failure
[1, 2, 3]
#==> result.empty?

## TEST: Boolean false expectation failure
[]
#=/=> result.empty?

## TEST: Result type failure
"hello"
#=:> Integer

## TEST: Performance timing failure
sleep(0.01)
#=%> 1
