library :tryouts, 'lib'
group "Syntax"

tryouts "Dreams" do
  
  setup do
    Tryouts.const_set :TEST_VALUE, 9000
  end
  
  drill "dream inline", :muggsy do
    :muggsy
  end
  
  dream :muggsy
  drill "dream on top" do
    :muggsy
  end
  
  dream do
    :muggsy
  end
  drill "dream output can be specified with a block" do
    :muggsy
  end
  
  dream :class do
    Symbol
  end
  drill "dream with a format argument and a block" do
    :muggsy
  end
  
  # NOTE: The constant is defined in the setup block which is called before the
  # drill block is executed. As of 0.8.2 the dream block is executed literally
  # just before the drill block which is why this test returns true. 
  dream do
    Tryouts.const_get :TEST_VALUE
  end
  drill "dream output from a block is executed just before the drill" do
    9000
  end
  
  ## NOTE: The following should raise a Tryouts::TooManyArgs error b/c dreams takes 1 arg
  #
  #dream :class, 2 do
  #  Symbol
  #end
  #drill "dream with a format argument and a block" do
  #  :muggsy
  #end
  #
  #drill "this drill will fail b/c it has no dream", :muggsy
  
end