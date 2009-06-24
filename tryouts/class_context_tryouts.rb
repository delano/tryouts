
group "Class context tests"

tryout "Setting class variables", :api do
  setup do
    class ::Olivia; end
    @@from_setup = Olivia.new  # NOTE: module_eval seems to solve this problem
    @from_setup = true
  end
  
  drill "created in setup", NameError, :exception do
    @@from_setup
  end
  
  drill "create class var", 'Olivia', :to_s  do
    @@from_drill = Olivia.new
    @@from_drill.class.to_s
  end
  
  drill "created in drill", 1, :size do
    @@from_drill
    self.class.class_variables
  end
  
end
