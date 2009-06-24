
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
  drill "can pass based on exception class" do
    bad_method_call
  end
  
  drill "dreamless drills that return true will pass" do
    true
  end
  
  drill "inline true values will pass", true
  drill "can specify inline return values", :food, :food
  drill "can specify regex format", 'Hi', /hi/i, :regex
  
end
