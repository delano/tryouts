
def method_missing(*a)
  p [:meth, a]
end

a=([1,2,3])

__END__
$: << File.dirname(__FILE__)
require 'tmp'

# test matches result with expectation
1 + 1
#=> 2

# test expectation type matters
'foo' + 'bar'
#=> 'foobar'
#=> 'foobar'

