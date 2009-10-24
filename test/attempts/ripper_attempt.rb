# FAILED
require 'pp'
require 'ripper'

sample = DATA.read
puts "LEX"
pp Ripper.lex(sample)

puts "SEXP"
pp Ripper.sexp(sample)


__END__
# test expectation type matters
'foo' + 'bar'
#=> 'foobar'
#=> 'foobar'

# test expectation type matters
foo = 1 + 1
@bar = 2 + 2
foo
#=> 2



