# try/test_performance_time_try.rb

## TEST: Very fast operation should pass loose timing
1 + 1
#=%> 1  # Allow up to 1ms (should easily pass)

## TEST: Sleep operation with reasonable expectation
sleep(0.01)  # Sleep for 10ms
#=%> 15     # Expect around 15ms (allows 10-11ms with 10% tolerance)

## TEST: Array creation should be very fast
Array.new(1000) { |i| i * 2 }
#=%> 1    # Should complete well under 1ms

## TEST: Should fail if timing is too strict
sleep(0.001)  # Sleep for 1ms
#=%> 0.1     # Expect 0.1ms (too strict, should fail)
