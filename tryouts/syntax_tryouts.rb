
tryout "DSL Syntax", :api do
  
  dream 4770744
  drill "can specify dream above the drill" do
    4770744
  end
  
  dream :class, Array
  drill "can pass based on output object class" do
    [1,2,3]
  end
  
  dream :exception, NameError
  drill "can pass based on exception class" do
    dream
    bad_method_call
    nil
  end
  
  drill "dreamless drills that return true will pass" do
    true
  end
  
  ##drill "will fail if given no path" do
  ##  dream nil, 1, "wrong number of arguments (0 for 1)"
  ##  Rudy::MetaData::Disk.new
  ##end
  
end
