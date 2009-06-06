
group "Class context tests"

tryout "Setting class variables", :api do
  setup do
    class ::Olivia; end
    @@from_setup = Olivia.new
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