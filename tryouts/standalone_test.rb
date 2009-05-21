## Standalone Test
#
# This tryout is intended to be run on its own, 
# without the tryouts exectuable. That's why it's
# named _test.rb, so tryouts won't see it. It uses
# the same dreams as MockoutCLI. 
# 
# Usage: ruby tryouts/standalone_test.rb
#

TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
TRYOUTS_LIB  = File.join(TRYOUTS_HOME, 'lib')
MOCKOUT_PATH = File.join(TRYOUTS_HOME, 'bin', 'mockout')
$:.unshift TRYOUTS_LIB # Put our local lib in first place

require 'tryouts'

class StandaloneCLI < Tryouts
  command :mockout, MOCKOUT_PATH
  dreams File.join(TRYOUTS_HOME, 'tryouts', 'mockoutcli_dreams.rb')
  
  tryout "common usage" do
    drill  'no command'
    drill     'no args',             :sergeant
    drill 'yaml output', :f, 'yaml', :sergeant
    drill 'json output', :f, 'json', :sergeant
  end
  
  tryout "inline dream will pass", :cli, :mockout do
    output = ['we expect mockout to2', 'echo these lines back']
    dream 'echo arguments', output
    # $ bin/mockout sergeant -e 'we expect mockout to' 'echo these lines back'
    drill 'echo arguments', :sergeant, :e, *output  
  end

end

StandaloneCLI.run