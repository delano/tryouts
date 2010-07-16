# run me with
#   ruby -rubygems -Ilib step1_tryouts.rb



a = 1
b = 2
a + b
# => 3


# multiple expectations
'foo2' + 'bar'
#=> 'foo2bar'
#=> 'foobar'


# test ignores comments before expectations
'foo'
# ignored comment
# ignored comment
#=> 'foo'


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
