# try/parsing/multiline_try.rb
# Tests for multi-line code handling

# test handles multiple code lines
# only  tests last line against expectation
str = ''
str << 'foo'
str << 'bar'
str
#=> 'foobar'
