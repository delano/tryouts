
TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..'))
MOCKOUT_PATH = File.join(TRYOUTS_HOME, 'bin', 'mockout')

group "mockout cli"
command :mockout, MOCKOUT_PATH

tryout "common usage" do
  drill  'no command'
  drill     'no args',             :info
  drill 'yaml output', :f, 'yaml', :info
  drill 'json output', :f, 'json', :info
end

tryout "inline dream that passes", :cli, :mockout do
  output = ['we expect mockout to', 'echo these lines back']

  # $ bin/mockout sergeant -e 'we expect mockout to' 'echo these lines back'
  drill 'echo arguments', :info, :e, output[0], output[1]
  dream 'echo arguments', output
end

tryout "inline dream that fails", :cli, :mockout do
  dream 'echo arguments', "The dream does"
  drill 'echo arguments', :info, :e, "not match reality"
end
