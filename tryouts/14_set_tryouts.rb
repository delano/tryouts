library :tryouts, 'lib'
group "Syntax"

tryouts "Set (initial)" do
  set :key1, 9000
  drill "set values are available outside drill/dream blocks", key1 do
    9000
  end
  drill "set values are available inside drill/dream blocks", 9000 do
    key1
  end
end

tryouts "Set (double check)" do

  dream :exception, NameError
  drill "set values are not available from other tryouts inside blocks" do
    key1
  end
  
  ## NOTE: This drill will create a runtime error b/c key1 isn't defined here.
  ## dream key1
  ## drill "set values are not available from other tryouts outside blocks" do
  ## end
    
end