require 'rubygems'
require 'hexoid'

POOP = 1

# TEST 1: test matches result with expectation
a = 1 + 1
#=> 2


## TEST 2: comments, tests, and expectations can 
## contain multiple lines
a = 1
b = 2
a + b
# => 3
# => 2 + 1

# TEST 3: test expectation type matters
'foo'.class
#=> String


# TEST 4: instance variables can be used in expectations
@a = 1
@a
#=> @a


# TEST 5: test ignores blank lines before expectations
@a += 1
'foo'


#=> 'foo'


# TEST 6: test allows whiny expectation markers for textmate users *sigh*
'foo'
# =>  'foo'


# TEST 7: test expectations can be commented out
'foo'
##=> 'this would fail'

x = raise rescue 'foo'
#=> 'foo'



