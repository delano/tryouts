
library :tryouts, File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

group "Mixins"



test_hash = { 
  :level1 => { 
    :level2 => {}, 
    :apples => 1 
   }, 
  :help => [1, :a, 900001, Object.new, Hash],
  :oranges => 90 
}


tryouts "Hash" do
  setup do
    
  end
  
  drill "knows the deepest point", test_hash.deepest_point, 3
  drill "has a last method", {}, :last, :respond_to?

end