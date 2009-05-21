

class MockoutCLI < Tryouts
  TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  MOCKOUT_PATH = File.join(TRYOUTS_HOME, 'bin', 'mockout')

  command :mockout, MOCKOUT_PATH
  dreams File.join(TRYOUTS_HOME, 'tryouts')
  
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
  
  tryout "inline dream will fail", :cli, :mockout do
    dream 'echo arguments', "The dream does"
    drill 'echo arguments', :sergeant, :e, "not match reality"
  end
  
  #tryout "groups", :api do
  #  drill "create default group" do
  #    rgroup = Rudy::Groups.new
  #    rgroup.create
  #  end
  #end

  
end
