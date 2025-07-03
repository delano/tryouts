#!/usr/bin/env ruby
# test_context_modes.rb

require_relative 'lib/tryouts'

test_file = '/Users/d/Projects/opensource/d/tryouts/try/step1_try.rb'

puts "Testing both context modes with: #{test_file}"
puts '=' * 60

# Test 1: Fresh context mode (default)
puts "\n🔄 Testing FRESH context mode..."
parser      = Tryouts::PrismParser.new(test_file)
testrun     = parser.parse
batch_fresh = Tryouts::TestBatch.new(testrun, shared_context: false)

Tryouts.instance_variable_set(:@debug, false)  # reduce noise

success_fresh = batch_fresh.run do |test_case|
  puts "  Fresh: #{test_case.description}"
end

puts "Fresh context results: #{batch_fresh.size} tests, #{batch_fresh.failed} failed"

puts "\n🔗 Testing SHARED context mode..."
batch_shared = Tryouts::TestBatch.new(testrun, shared_context: true)

success_shared = batch_shared.run do |test_case|
  puts "  Shared: #{test_case.description}"
end

puts "Shared context results: #{batch_shared.size} tests, #{batch_shared.failed} failed"

puts "\n📊 Summary:"
puts "  Fresh context:  #{success_fresh ? '✅' : '❌'} (#{batch_fresh.failed} failures)"
puts "  Shared context: #{success_shared ? '✅' : '❌'} (#{batch_shared.failed} failures)"
