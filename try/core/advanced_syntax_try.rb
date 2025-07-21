# try/core/advanced_syntax_try.rb
# Tests for advanced features: exceptions, helper methods, multiple expectations

puts 'if you can see this, step2 setup succeeded'

def example_of_an_inline_test_helper_method
  'I am helping'
end

## some addition
a = 1
b = 2
a + b + 1
# => 4

# multiple expectations
'foo' + 'bar'
#=> 'foobar'
#=> :foobar.to_s

# test ignores comments before expectations
'foo'
# ignored comment
# ignored comment
#=> 'foo'

## test uses a helper method defined at the top of this file.
example_of_an_inline_test_helper_method
#=> 'I am helping'

## Example of handling exceptions (common syntax)
begin
  raise 'foo'
rescue StandardError => e
  [e.class, 'foo']
end
#=> [RuntimeError, 'foo']

## Standard Exception Test
raise StandardError.new("test message")
#=!> error.message == "test message"

## Exception Type Test
raise ArgumentError.new("bad argument")
#=!> error.is_a?(ArgumentError)

## Exception Message Pattern Test
raise StandardError.new("Key not found in Redis: test:key")
#=!> error.message.include?("Key not found in Redis")

## Regular expectation still works
"hello".upcase
#=> "HELLO"

## Messy test with multiple lines of code
## intermixed with comments. Only the last
## line is treated as an expectation.

phrase_template = '%s %d %s'
# inline comment
phrase = format(phrase_template, 'foo', 1, 'bar')

# another comment
#=> 'foo 1 bar'
