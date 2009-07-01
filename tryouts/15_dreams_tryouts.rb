library :tryouts, 'lib'
group "Syntax"

tryouts "Dreams" do
  
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
  drill "dream output in a block" do
    :muggsy
  end
  
  dream :class do
    Symbol
  end
  drill "dream with a format argument and a block" do
    :muggsy
  end
    
  ##dream :class, 2 do
  ##  Symbol
  ##end
  ##drill "dream with a format argument and a block" do
  ##  :muggsy
  ##end
  
end