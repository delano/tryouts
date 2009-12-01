# FAILED
require 'pp'
require 'ripper'

sample = DATA.read
puts "LEX"
pp Ripper.lex(sample)

puts "SEXP"
a = Ripper.sexp(sample)
pp a
__END__
:a + :a
class Test
 def test_foo
   assert_equal(2) {
     1 + 1 if true
   }
 end
end

# test expectation type matters
#'foo' + 'bar'
#Test.box('heya') do
#  1 / 2
#end
#=> 'foobar'
#=> 'foobar'

# test expectation type matters
#foo = 1 + 1
#@bar = 2 + 2
#foo
#=> 2



