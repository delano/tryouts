# This file has a syntax error to test the exit code
puts "Testing syntax error handling"

# Intentional syntax error
def broken_method
  if true
    puts "missing end"
# Missing "end" statement