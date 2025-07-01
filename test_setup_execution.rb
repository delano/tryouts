#!/usr/bin/env ruby
# test_setup_execution.rb

require_relative 'lib/tryouts'

test_file = '/Users/d/Projects/opensource/d/tryouts/try/step1_try.rb'

puts "Testing TestBatch setup execution with: #{test_file}"
puts '=' * 50

begin
  parser = Tryouts::PrismParser.new(test_file)
  testrun = parser.parse

  puts "✅ Parsed #{testrun.total_tests} test cases"
  puts "🏗️  Setup: #{testrun.setup.empty? ? 'Empty' : testrun.setup.code.lines.count} lines"
  puts "🧹 Teardown: #{testrun.teardown.empty? ? 'Empty' : testrun.teardown.code.lines.count} lines"
  puts

  batch = Tryouts::TestBatch.new(testrun)

  puts "🧪 Running TestBatch with fresh context per test..."

  Tryouts.instance_variable_set(:@debug, true)

  success = batch.run do |test_case|
    puts "  Executed: #{test_case.description}"
  end

  puts
  puts "📊 Results:"
  puts "  Total tests: #{batch.size}"
  puts "  Failed tests: #{batch.failed}"
  puts "  Success: #{success ? '✅' : '❌'}"

rescue StandardError => ex
  puts "❌ Error: #{ex.message}"
  puts ex.backtrace.first(10)
end
