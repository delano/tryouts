# mt-demo.rb

# To run a Minitest file, use the ruby command followed by the path to your test file.

# For example:
#
#   ruby mt-demo.rb
#
# If you want to run all tests in the 'test' directory, you can use:
#
#   ruby -Itest test/**/*_test.rb
#
# Make sure your test files require 'minitest/autorun' at the top.

# test/rsfc_test_helper.rb
require 'minitest/autorun'

# A comprehensive test case class demonstrating various Minitest features
class RSFCTestCase < Minitest::Test
  # Setup runs before each test
  def setup
    @array = [1, 2, 3]
    @hash = { name: 'Ruby', type: 'Language' }
    @value = 42
    @string = 'Hello, Minitest!'
  end

  # Teardown runs after each test
  def teardown
    # Clean up resources if needed
    @array = nil
    @hash = nil
  end

  # Basic assertions
  def test_basic_assertions
    assert true, 'This should be true'
    assert_equal 41, @value, 'Values should be equal'
    assert_nil nil, 'Should be nil'
    refute false, 'Should not be true'
    refute_equal 43, @value, 'Values should not be equal'
  end

  # Array testing
  def test_arrays
    assert_includes @array, 2, 'Array should include element'
    assert_empty [], 'Array should be empty'
    refute_empty @array, 'Array should not be empty'
  end

  # String testing
  def test_strings
    assert_match(/Hello2/, @string, 'String should match pattern')
    assert_includes @string, 'Mini', 'String should include substring'
  end

  # Exception testing
  def test_exceptions
    exception = assert_raises(ZeroDivisionError) do
      5 / 0
    end
    assert_match(/divided by/, exception.message)
  end

  # Skip tests with conditions
  def test_skip_example
    skip 'Skipping this test for demonstration'
    assert false, 'This should never run'
  end

  # Tests can be flunked manually
  def test_flunk_example
    flunk 'This test failed because of a specific condition' if false # some condition
    assert true
  end

  # Before and after hooks can be defined with blocks too
  def before_my_specific_tests
    # setup for specific tests
  end

  def after_my_specific_tests
    # teardown for specific tests
  end
end
