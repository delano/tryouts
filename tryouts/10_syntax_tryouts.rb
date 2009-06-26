
tryout "DSL Syntax", :api do
  
  drill "can specify a dream inline", 3 do
    12 / 4
  end
    
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
    bad_method_call
  end
  
  drill "dreamless drills that return true will pass" do
    true
  end
  
  drill "inline true values will pass too", true
  drill "can specify inline return values", :food, :food
  drill "can specify match format", 'mahir', :match, /..hi./i
  
  dream "big"
  dream :class, String
  dream :match, /\Ab.g\z/
  drill "can handle multiple dreams" do
    "big"
  end
  
  drill "can specify gt (>) format", 2, :gt, 1
  drill "can specify gte (>=) format", 2, :gte, 2 
  drill "can specify lt (<) format", 1, :lt, 2
  drill "can specify lte (<=) format", 2, :lte, 2
  
  drill "can run arbitrary formats", [3,1,2], :sort, [1,2,3]
end
