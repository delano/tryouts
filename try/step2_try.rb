# run me with
#   ruby -rubygems -Ilib step1_tryouts.rb


## some addition
a = 10
b = 2
a + b + 1
# => 4


# multiple expectations
'foo' + 'bar'
#=> 'foobar'
#=> :foobar.to_s


# test ignores comments before expectations
'foo'
# ignored comment
# ignored comment
#=> 'foo2'


## test uses helper methods
## ( #foo is defined on top of file )
#foo()
##=> foo


#begin
#  raise
#rescue
#  'foo'
#end
##=> 'foo'

## test handles multiple code lines
## only only tests last line against expectation
#str = ""
#str << 'foo'
#str << 'bar'
#str
##=> 'foobar'
##
### test failure
##'this fails'
###=> 'expectation not met'
#


# 
# require 'pathname'
# require Pathname(__FILE__).dirname.parent + 'lib/nofw'
# 
# # test failure
# 'this fails'
# #=> 'expectation not met'
# 
