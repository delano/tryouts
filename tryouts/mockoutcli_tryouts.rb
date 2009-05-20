TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
TRYOUTS_LIB  = File.join(TRYOUTS_HOME, 'lib')
MOCKOUT_PATH = File.join(TRYOUTS_HOME, 'bin', 'mockout')
$:.unshift TRYOUTS_LIB # Put our local lib in first place

require 'tryouts'

class MockoutCLI < Tryouts
  command :mockout, MOCKOUT_PATH
  
  tryout "common usage" do
    drill  'no command'
    drill     'no args',             :sergeant
    drill 'json output', :f, 'json', :sergeant
    drill 'yaml output', :f, 'yaml', :sergeant
  end
  
  tryout "inline dream", :cli, :mockout do
    output = ['we expect mockout to', 'echo these lines back']
    
    #dream output
    
    # $ bin/mockout sergeant -e 'we expect mockout to' 'echo these lines back'
    drill 'echo', :sergeant, :e, *output  
  end
  
  #tryout "groups", :api do
  #  drill "create default group" do
  #    rgroup = Rudy::Groups.new
  #    rgroup.create
  #  end
  #end

  
end

MockoutCLI.run