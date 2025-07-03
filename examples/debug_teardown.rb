#!/usr/bin/env ruby
# debug_teardown.rb

require_relative '../lib/tryouts'

test_file = 'try/proof1_try.rb'
parser    = Tryouts::PrismParser.new(test_file)
testrun   = parser.parse

puts 'Debug teardown detection:'
puts "Total lines: #{File.readlines(test_file).size}"
puts "Test cases: #{testrun.test_cases.size}"

testrun.test_cases.each_with_index do |tc, i|
  puts "Test #{i + 1}: lines #{tc.line_range.first}..#{tc.line_range.last}"
end

puts "Teardown code length: #{testrun.teardown.code.length}"
puts "Teardown range: #{testrun.teardown.line_range}"
puts "Teardown code: '#{testrun.teardown.code}'"
