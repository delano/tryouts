# try/core/constant_shadowing_try.rb
#
# frozen_string_literal: true

#
# Tests for constant shadowing edge cases in type expectations
# Verifies that class type expectations work correctly even when
# class constants are shadowed by local variables or methods

# Setup classes used in tests
class CustomTestClass
  def initialize(value)
    @value = value
  end

  def to_s
    "custom_#{@value}"
  end
end

module TestMod
end

class TestClassWithMod
  include TestMod
end

## TEST: Basic String class expectation works
str = "hello_world"
str
#=:> String

## TEST: Multiple expectations with String type check
value = "test_value"
value
#=:> String
#=/=> _.empty?
#==> _.length > 5
#=~> /test/

## TEST: Type check works when String method is defined
def String
  "method_override"
end

# This should still pass because the fix uses ::String constant
test_string = "should_work_with_method"
test_string
#=:> String

## TEST: Type check works with other shadowed constants
def Array
  "array_method"
end

test_array = [1, 2, 3]
test_array
#=:> Array
#==> _.size == 3

## TEST: Hash type with potential shadowing
def Hash
  {}
end

test_hash = {a: 1, b: 2}
test_hash
#=:> Hash
#=/=> _.empty?

## TEST: Custom class definition and type check
custom_obj = CustomTestClass.new("test")
custom_obj
#=:> CustomTestClass
#==> _.to_s.include?("custom")

## TEST: Numeric type expectations with shadowing
def Integer
  "not_an_integer"
end

def Float
  "not_a_float"
end

num1 = 42
num1
#=:> Integer
#==> _ > 40

## TEST: Float type expectation with shadowing
num2 = 3.14
num2
#=:> Float
#==> _ > 3.0

## TEST: Boolean type expectations with method shadowing
def TrueClass
  "fake_true"
end

def FalseClass
  "fake_false"
end

bool_val1 = true
bool_val1
#=:> TrueClass

## TEST: False class expectation with shadowing
bool_val2 = false
bool_val2
#=:> FalseClass

## TEST: Symbol and Regexp with shadowing
def Symbol
  "not_a_symbol"
end

def Regexp
  "not_a_regexp"
end

## TEST: Symbol type expectation with shadowing
sym = :test_symbol
sym
#=:> Symbol

## TEST: Regexp type expectation with shadowing
regex = /pattern/
regex
#=:> Regexp

## TEST: Module inheritance still works with shadowing
def Module
  "fake_module"
end

## TEST: Custom class with module inclusion despite shadowing
obj_with_mod = TestClassWithMod.new
obj_with_mod
#=:> TestClassWithMod

## TEST: Object inheritance works despite method definitions
def Object
  "not_the_object_class"
end

## TEST: Object inheritance works despite method definitions
# String should still be recognized as Object
final_string = "inheritance_test"
final_string
#=:> Object
#=:> String
#=/=> _.empty?
