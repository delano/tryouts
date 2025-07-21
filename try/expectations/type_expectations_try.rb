# try/expectations/type_expectations_try.rb

## TEST: Result type expectations work correctly
"hello world"
#=:> String

## TEST: Array type check
[1, 2, 3]
#=:> Array

## TEST: Integer type check
42
#=:> Integer

## TEST: Should fail with wrong type
"hello"
#=:<> Integer

## TEST: Supports ancestors
"hello"
#=:> Object
