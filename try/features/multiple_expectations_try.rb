# try/features/multiple_expectations_try.rb

## TEST: Returns an array, has multiple expectations
[1, 2, 3]
#=> [1, 2, 3]
#=> result.class == Array
#==> result.size.positive?  # must evaluate to true
#=/=> result.size.negative?  # must evaluate to false
#=> result.size == 3
#=> result.length > 2
#!=> result.size/0  # must raise an error

## TEST: Returns a string, has multiple expectations
"hello"
#:=> String  # compare class
#==> result.upcase == "HELLO"
#==> "HELLO".downcase
#*=> /.el+o/
#=> 'hello'

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
