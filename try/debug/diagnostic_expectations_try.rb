# try/debug/diagnostic_expectations_try.rb
# Requires enhanced parser for #=?> diagnostic syntax

# Setup variables for diagnostic testing
@debug_counter = 0
@test_data = { name: 'alice', age: 30, items: [1, 2, 3] }

## TEST: Basic diagnostic expectation - shows debug info on failure
a = 1
b = 2
result = a + b
#=?> @debug_counter += 1  # Diagnostic: increment counter
#=?> "Debug: a=#{a}, b=#{b}, result=#{result}"  # Diagnostic: show values
#=> 4  # This will fail intentionally to show diagnostic output

## TEST: Diagnostic with complex data structures
user_data = @test_data.dup
user_data[:age] += 1
#=?> user_data.keys  # Diagnostic: show available keys
#=?> user_data[:items].length  # Diagnostic: show array length
#=> { name: 'alice', age: 32, items: [1, 2, 3] }  # This will fail to show diagnostics

## TEST: Diagnostic that catches exceptions
risky_operation = lambda { 1 / 0 }
#=?> "About to perform risky operation"  # Diagnostic: operation context
begin
  result = risky_operation.call
rescue => e
  result = "Error: #{e.class}"
end
#=?> "Operation completed with result: #{result}"  # Diagnostic: final state
#=> "Error: ZeroDivisionError"

## TEST: Multiple diagnostics in successful test (should not show)
x = 10
y = 20
sum = x + y
#=?> "Input values: x=#{x}, y=#{y}"  # Diagnostic: inputs
#=?> "Intermediate calculation: #{x} + #{y}"  # Diagnostic: calculation
#=?> "Final sum: #{sum}"  # Diagnostic: result
#=> 30  # This should pass, so diagnostics won't be shown

## TEST: Diagnostic with method calls and state inspection
class TestHelper
  def initialize
    @internal_state = 'initialized'
  end

  def process(value)
    @internal_state = 'processing'
    value * 2
  end

  def state
    @internal_state
  end
end

helper = TestHelper.new
processed = helper.process(5)
#=?> helper.state  # Diagnostic: check internal state
#=?> "Processed value: #{processed}"  # Diagnostic: show result
#=> 11  # This will fail to demonstrate diagnostic output

## TEST: Diagnostic expectations never fail the test
failing_diagnostic = lambda { raise "Diagnostic error" }
#=?> failing_diagnostic.call  # This diagnostic will error but test continues
regular_result = "success"
#=> "success"  # Test should still pass despite diagnostic error

## TEST: Diagnostic with performance timing context
start_time = Time.now
sleep(0.001)  # Small delay
elapsed = Time.now - start_time
#=?> "Operation took #{(elapsed * 1000).round(2)}ms"  # Diagnostic: timing info
#=?> elapsed > 0  # Diagnostic: timing validation
#=> start_time.class  # This will fail to show timing diagnostics

## TEST: Edge case - empty diagnostic expression
value = 42
#=?>   # Empty diagnostic - should handle gracefully
#=> 42
