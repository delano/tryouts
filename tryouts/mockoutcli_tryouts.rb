

TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
MOCKOUT_PATH = File.join(TRYOUTS_HOME, 'bin', 'mockout')

group "mockout cli"
command :mockout, MOCKOUT_PATH

tryout "common usage" do
  drill  'no command'
  drill     'no args',             :sergeant
  drill 'yaml output', :f, 'yaml', :sergeant
  drill 'json output', :f, 'json', :sergeant
end

tryout "inline dream that passes", :cli, :mockout do
  output = ['we expect mockout to', 'echo these lines back']
  dream 'echo arguments', output
  # $ bin/mockout sergeant -e 'we expect mockout to' 'echo these lines back'
  drill 'echo arguments', :sergeant, :e, *output  
end

tryout "inline dream that fails", :cli, :mockout do
  dream 'echo arguments', "The dream does"
  drill 'echo arguments', :sergeant, :e, "not match reality"
end
