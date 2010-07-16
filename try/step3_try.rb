require 'pathname'
require Pathname(__FILE__).dirname.parent + 'lib/nofw'

def foo() 'foo'; end


begin
  raise
rescue
  'foo'
end
#=> 'foo'

# test handles multiple code lines
# only only tests last line against expectation
str = ""
str << 'foo'
str << 'bar'
str
#=> 'foobar'



