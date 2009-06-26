

group "Mixins"

test_hash = { 
  :level1 => { 
    :level2 => {}, 
    :apples => 1 
   }, 
  :help => [1, :a, 900001, Object.new, Hash],
  :oranges => 90 
}


tryouts "Hash", :api do
  setup do
    
  end
  
  drill "knows the deepest point", test_hash.deepest_point, 3
  drill "has a last method", {} #, :respond_to?, :last

end