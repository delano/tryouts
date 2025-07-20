# try/features/multiple_expectations_try.rb

## TEST: Multiple expectations with smart detection
a = [1, 2, 3]
#=> [1, 2, 3]
#=> result.class == Array
#==> a.size.positive?  # must evaluate to true
#=/=> a.size.negative?  # must evaluate to false
#=> a.size == 3
#=> result.length > 2
#!=> result.size/0 # we expect an error

## TEST: Traditional single expectation still works
"hello"
#:=> String
#==> result.upcase == "HELLO"
#=/=>
#=> 'hello'
#=> result.size >= 5
#*=> /.el+o/

## TEST: Mixed boolean and value expectations
user = { name: "Alice", age: 30 }
#=> user
#=> result.has_key?(:name)
#=> result[:name] == "Alice"
#=> user[:age] >= 18

## TEST: Complex boolean expressions
numbers = (1..10).to_a
#=> numbers.include?(5) && numbers.length == 10
#=> result.all? { |n| n.is_a?(Integer) }
#=> numbers.first == 1 and numbers.last == 10
