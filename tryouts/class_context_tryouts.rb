
group "Class context tests"

xtryout "Setting class variables", :api do
  setup do
    class ::Olivia; end
    @@from_setup = Olivia.new  # NOTE: module_eval seems to solve this problem
    @from_setup = true
  end
  
  drill "created in setup" do
    @@from_setup
  end
  
  drill "created in drill" do
    @@from_setup
    self.class.class_variables
  end
  
end

dreams "Setting class variables" do
  dream "created in setup", 'Olivia', :to_s
  dream "created in drill", ''
end