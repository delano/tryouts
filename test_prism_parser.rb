#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test of the new Prism parser

require_relative 'lib/tryouts'

# Test the Prism parser with an existing tryout file
test_file = '/Users/d/Projects/opensource/d/tryouts/try/step1_try.rb'

puts "Testing Prism parser with: #{test_file}"
puts "=" * 50

begin
  parser = Tryouts::PrismParser.new(test_file)
  testrun = parser.parse

  puts "✅ Parsing successful!"
  puts "📊 Found #{testrun.total_tests} test cases"
  puts "🏗️  Setup code: #{testrun.setup.empty? ? 'None' : 'Present'}"
  puts "🧹 Teardown code: #{testrun.teardown.empty? ? 'None' : 'Present'}"
  puts

  testrun.test_cases.each_with_index do |tc, i|
    puts "Test #{i + 1}: #{tc.description}"
    puts "  Code lines: #{tc.code.lines.count}"
    puts "  Expectations: #{tc.expectations.size}"
    puts "  Range: #{tc.line_range}"
    puts
  end

  # Test RSpec translation
  puts "🧪 Testing RSpec translation..."
  rspec_translator = Tryouts::Translators::RSpecTranslator.new
  rspec_code = rspec_translator.generate_code(testrun)
  puts "✅ RSpec code generated (#{rspec_code.lines.count} lines)"

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end
