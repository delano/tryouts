
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

class ::SubHash < Hash; end
class ::SubHash2 < Hash; end

nub = ::SubHash2.new
nub[:level1] = ::SubHash.new
nub[:level1][:level2] = ::SubHash.new

tryouts "Hash" do
  setup do
    
  end
  
  drill "knows the deepest point", test_hash.deepest_point, 3
  drill "has a last method", {}, :last, :respond_to?

  drill "can calculate a SHA1 hash", test_hash.gash do
    test_hash.gash
  end
  
  drill "different subclasses of hash have different gash", nub.gash, :ne do
    sub = ::SubHash.new
    sub[:level1] = ::SubHash.new
    sub[:level1][:level2] = ::SubHash.new
    sub.gash
  end
end