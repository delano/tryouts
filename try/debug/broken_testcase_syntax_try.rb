# try/debug/broken_testcase_syntax_try.rb

# Intentionally incorrect expectation syntax should still be parsed
# in a way that doesn't lump everything into a setup section up to
# the first test case with a valid expectation.

## First broken expectation
1 + 1
#=$BOGUS$> 2

## Second broken expectation
2 + 2
#=$$BOGUS$$> 4

## Third broken expectation
3 + 3
#=$$$STILLBOGUS$$$> 6

## Fourth testcase, but first with a correct expectation
4 + 4
#=> 8
