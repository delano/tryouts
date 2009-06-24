
group "Class context tests"

tryout "Setting class variables", :api do
  setup do
    class ::Olivia; end
    @@from_setup = Olivia.new  # NOTE: module_eval seems to solve this problem
    @from_setup = true
  end
  
  drill "can't access class var created in setup (1.9 only)", NameError, :exception do
    @@from_setup
  end
  
  xdrill "can access class var created in setup (1.8 only)", 'Olivia', :to_s do
    @@from_setup.class.to_s
  end
  
  drill "create class var", 'Olivia', :to_s  do
    @@from_drill = Olivia.new
    @@from_drill.class.to_s
  end
  
  drill "can access class var created in drill", 'Olivia', :to_s do
    @@from_drill.class.to_s
  end
  
end
