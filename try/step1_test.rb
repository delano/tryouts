# Generated minitest code for try/step1_try.rb
# Updated: 2025-07-01 16:38:58 -0700

require 'minitest/test'
require 'minitest/autorun'

class Teststep1try < Minitest::Test
  def setup
    puts 'If you see this the setup ran correctly.'
  end

  def test_000_test_matches_result_with_expectation
    result = begin
      a = 1 + 1
    end
    assert_equal 2, result
  end

  def test_002_contain_multiple_lines
    result = begin
      a = 1
      b = 2
      a + b
    end
    assert_equal 3, result
    assert_equal 2 + 1, result
  end

  def test_003_test_expectation_type_matters
    result = begin
      'foo'.class
    end
    assert_equal String, result
  end

  def test_004_instance_variables_can_be_used_in_expectations
    result = begin
      @a = 1
      @a
    end
    assert_equal @a, result
  end

  def test_005_test_ignores_blank_lines_before_expectations
    result = begin
      @a += 1
      'foo'

    end
    assert_equal 'foo', result
  end

  def test_006_test_allows_whiny_expectation_markers_for_textmate_users_sigh
    result = begin
      'foo'
    end
    assert_equal 'foo', result
  end

  def teardown
    x = begin
      raise
    rescue StandardError
      'if you can see this, teardown succeeded'
    end  # noqa
    puts x
  end
end
