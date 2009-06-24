
library :tryouts, File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

group "Mixins"

tryouts "Hash" do
  
  dream 3, :deepest_point
  drill "knows the deepest point", { :level1 => { :level2 => {} } }
  
  dream :Hash, :last
  drill "has a last method", {}
  
end