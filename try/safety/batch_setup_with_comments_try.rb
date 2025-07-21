puts "start of setup"
require_relative '../../lib/tryouts'

# An arbitrary comment in the setup should not affect how the setup or testcases are parsed.
test_file = 'try/safety/batch_setup_with_comments_try.rb'
puts 'end of setup'

# We instantiate the parser just for fun
@parser = Tryouts::PrismParser.new(test_file)

## TEST: Just a simple non-nil check?
@parser
#=/=> _.nil?


# start of teardown
puts 'the end'



# end of teardown
