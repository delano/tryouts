
require 'pathname'
require Pathname(__FILE__).dirname.parent + 'lib/nofw'

# test failure
'this fails'
#=> 'expectation not met'

