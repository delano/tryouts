# try/expectations/combined_features_try.rb
#
# frozen_string_literal: true

## TEST: Intentional failure with output - stderr should NOT contain specific text
puts "This goes to stdout"
$stderr.puts "Different error message"
#=<> "This text should not be in stderr"  # Intentional failure on stdout content
#=2> "Different error"  # But stderr should contain this

## TEST: Combining output and intentional failure expectations
puts "Success message"
#=1> "Success"
#=<> result.include?("Failure")  # Should pass because result doesn't contain "Failure"

## TEST: Multiple expectation types together
x = [1, 2, 3]
puts "Array length: #{x.length}"
x
#=> [1, 2, 3]           # Regular expectation
#=:> Array              # Type expectation
#=1> "Array length: 3"  # Output expectation
#=<> result.empty?      # Intentional failure expectation
