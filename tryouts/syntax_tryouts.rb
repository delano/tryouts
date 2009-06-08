
tryout "DSL Syntax", :api do
  
  drill "Dream in the drill" do
    dream :heat, 2
    # ... some drill stuff
    [:heat, 2]
  end
  
  drill "Drills that return true are assumed to pass" do
    :true
  end
  
  ##drill "will fail if given no path" do
  ##  dream nil, 1, "wrong number of arguments (0 for 1)"
  ##  Rudy::MetaData::Disk.new
  ##end
  
end
