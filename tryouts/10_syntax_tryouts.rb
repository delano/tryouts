
tryout "DSL Syntax", :api do
  
  dream 4770744
  drill "can specify dream above the drill" do
    4770744
  end
  
  dream Array, :class
  drill "can pass based on output object class" do
    [1,2,3]
  end
  
  dream NameError, :exception
  xdrill "can pass based on exception class" do
    bad_method_call
  end
  
  drill "dreamless drills that return true will pass" do
    true
  end
  
  drill "inline true values will pass too", true
  drill "can specify inline return values", :food, :food
  drill "can specify match format", 'mahir', /..hi./i, :match
  
  dream "big"
  dream String, :class
  dream /\Ab.g\z/, :match
  drill "can handle multiple dreams" do
    "big"
  end
  
  drill "can specify gt (greater than) format", 2, 1, :gt
  drill "can specify gte (greater than or equal to) format", 2, 2, :gte
  drill "can specify lt (less than) format", 1, 2, :lt
  drill "can specify lte (less then or equal to) format", 2, 2, :lte
  
  drill "can run arbitrary formats", [3,1,2], [1,2,3], :sort
end
