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

## TEST: Supports ancestors
"hello"
#=:> Object

## TEST: Multiple expectations with String class check first
value = "test_string"
value
#=:> String
#=/=> _.empty?
#==> _.length > 5

## TEST: Multiple expectations with String class check in middle
value2 = "another_test"
value2
#=/=> _.empty?
#=:> String
#==> _.include?("test")

## TEST: Multiple expectations with String class check last
value3 = "final_test"
value3
#=/=> _.nil?
#==> _.length > 5
#=:> String

## TEST: Hash type with multiple expectations
hash = {key: "value", count: 42}
hash
#=:> Hash
#==> _.keys.include?(:key)
#=/=> _.empty?

## TEST: Numeric types with expectations
number = 123
number
#=:> Integer
#==> _ > 100
#==> _.odd?

## TEST: Boolean type expectations
bool_true = true
bool_true
#=:> TrueClass

## TEST: Boolean false type expectation
bool_false = false
bool_false
#=:> FalseClass

## TEST: Symbol and regex types
symbol = :test_symbol
symbol
#=:> Symbol

## TEST: Regexp type expectation
pattern = /test_pattern/
pattern
#=:> Regexp

## TEST: Class inheritance with multiple expectations
str_obj = "inheritance_test"
str_obj
#=:> Object
#==> _.respond_to?(:to_s)
#=/=> _.nil?
