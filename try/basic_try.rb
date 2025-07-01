
@customer = Customer.new

## TEST 1: test matches result with expectation
a = 1 + 1
#=> 2

## TEST 2: More testing with a
## longer description and two expectations
a = 1 + 2
3 * plop
#=> 3
#=> 2 + 1

## TEST 3: another test matches result with expectation
b = 10/2
c = 5
b * c
#=> 25
#=> 25
#=> 25
#=> 25

## TEST 4
begin
  raise "An error"
rescue => e
  e
end
#=> "An error"


@customer.destroy
