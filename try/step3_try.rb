

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



