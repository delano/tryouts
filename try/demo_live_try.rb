# try/demo_live_try.rb
#
# frozen_string_literal: true

# Setup
puts 'Starting comprehensive live formatter demo...'
puts 'This demo showcases real-time status updates during test execution'

## TEST: Basic arithmetic operations
puts 'Testing basic arithmetic...'
sleep(0.1)  # Small delay to see status update
2 + 2
#=<> 5

## TEST: String operations and interpolation
puts 'Processing string operations...'
sleep(0.15)
name     = 'Tryouts v3.0'
"Welcome to #{name}!"
#=> "Welcome to Tryouts v3.0!"

## TEST: Array transformations
puts 'Transforming arrays...'
sleep(0.12)
numbers = [1, 2, 3, 4, 5, 6, 7, 8]
numbers.map { |n| n ** 2 }
#=> [1, 4, 9, 16, 25, 36, 49, 64]

## TEST: Hash operations
puts 'Working with hashes...'
sleep(0.08)
user      = { name: 'Alice', age: 28, role: 'developer' }
user.transform_keys(&:to_s).transform_values(&:to_s)
#=> {"name"=>"Alice", "age"=>"28", "role"=>"developer"}

## TEST: Boolean logic evaluation
puts 'Evaluating boolean expressions...'
sleep(0.1)
[10, 20, 30, 40, 50]
#==> _.length == 5
#==> _.sum == 150
#=/=> _.empty?

## TEST: Type checking with classes
puts 'Checking data types...'
sleep(0.09)
Time.now
#=:> Time

## TEST: Regular expression matching
puts 'Validating patterns with regex...'
sleep(0.11)
'developer@tryouts.example.com'
#=~> /\A[^@]+@[^@]+\.[a-zA-Z]{2,}\z/

## TEST: Performance timing test
puts 'Running performance benchmark...'
sleep(0.02)  # Intentionally quick operation
#=%> 50  # Allow up to 50ms

## TEST: First intentional failure
puts 'Demonstrating failure handling...'
sleep(0.13)
3 * 4
#=<> 13  # This should fail (3*4=12, not 13)

## TEST: File system operations simulation
puts 'Simulating file operations...'
sleep(0.16)
files      = ['config.rb', 'models.rb', 'helpers.rb']
files.select { |f| f.end_with?('.rb') }
#=> ["config.rb", "models.rb", "helpers.rb"]

## TEST: Complex data structure manipulation
puts 'Processing nested data structures...'
sleep(0.14)
projects    = [
  { name: 'tryouts', lang: 'ruby', stars: 42 },
  { name: 'parser', lang: 'ruby', stars: 18 },
  { name: 'formatter', lang: 'ruby', stars: 23 },
]
projects.sum { |p| p[:stars] }
#=> 83

## TEST: Exception handling demonstration
puts 'Testing exception handling...'
sleep(0.1)
risky_operation = -> { raise ArgumentError, 'Invalid argument provided' }
risky_operation.call
#=!> ArgumentError

## TEST: Mathematical computations
puts 'Computing mathematical functions...'
sleep(0.18)
angles      = [0, 30, 45, 60, 90].map { |deg| deg * Math::PI / 180 }
angles.map { |rad| Math.sin(rad).round(3) }
#=> [0.0, 0.5, 0.707, 0.866, 1.0]

## TEST: String pattern analysis
puts 'Analyzing text patterns...'
sleep(0.12)
text       = <<~SAMPLE
  The quick brown fox jumps over the lazy dog.
  This sentence contains every letter of the alphabet.
  Perfect for testing text processing algorithms.
SAMPLE
text.split.length
#=> 23

## TEST: Data filtering and aggregation
puts 'Filtering and aggregating data...'
sleep(0.15)
transactions = [
  { type: 'credit', amount: 100 },
  { type: 'debit', amount: 25 },
  { type: 'credit', amount: 75 },
  { type: 'debit', amount: 40 },
]
credits      = transactions.select { |t| t[:type] == 'credit' }
credits.sum { |t| t[:amount] }
#=> 175

## TEST: Second intentional failure
puts 'Another failure demonstration...'
sleep(0.11)
[1, 2, 3, 4, 5].length
#=<> 4  # This should fail (length is 5, not 4)

## TEST: Recursive algorithm demonstration
puts 'Running recursive algorithms...'
sleep(0.2)  # Longer delay for complex operation
factorial = lambda do |n|
  return 1 if n <= 1

  n * factorial.call(n - 1)
end
factorial.call(6)
#=> 720

## TEST: Date and time operations
puts 'Processing date and time...'
sleep(0.13)
now            = Time.now
now.strftime('%Y-%m-%d')
#=~> /\d{4}-\d{2}-\d{2}/

## TEST: Collection operations with enumerable
puts 'Advanced collection processing...'
sleep(0.17)
range_data = (1..20).to_a
evens      = range_data.select(&:even?)
odds       = range_data.select(&:odd?)
[evens, odds]
#==> _[0].length == 10
#==> _[1].length == 10

## TEST: Third intentional failure - type mismatch
puts 'Type validation failure...'
sleep(0.09)
'123'
#=:> Integer  # This should fail (it's a String, not Integer)

## TEST: Network simulation
puts 'Simulating network operations...'
sleep(0.25)  # Simulate network delay
response_codes = [200, 200, 404, 200, 500, 200]
response_codes.count(200).to_f / response_codes.length
#=> 0.6666666666666666

## TEST: Algorithm complexity demonstration
puts 'Testing algorithm performance...'
sleep(0.19)
data_set    = Array.new(1000) { rand(1..100) }
sorted_data = data_set.sort
sorted_data[sorted_data.length / 2]
#==> _.is_a?(Integer)

## TEST: Configuration parsing simulation
puts 'Parsing configuration data...'
sleep(0.14)
config    = {
  database: { host: 'localhost', port: 5432 },
  cache: { ttl: 3600, enabled: true },
  logging: { level: 'info', file: '/var/log/app.log' },
}
config[:database]
#=> { host: "localhost", port: 5432 }

## TEST: Final comprehensive test
puts 'Running final validation...'
sleep(0.22)
summary      = {
  tests_run: 24,
  passing: 21,
  failing: 3,
  duration: '~5 seconds',
}
(summary[:passing].to_f / summary[:tests_run] * 100).round(1)
#=> 87.5

## TEST: Cleanup and finalization
puts 'Cleaning up resources...'
sleep(0.1)
:completed
#=> :completed

# Teardown
puts 'Live formatter comprehensive demo completed!'
puts 'Total test cases: 24 with mixed results for demonstration'
