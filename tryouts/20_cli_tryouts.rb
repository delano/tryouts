
TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), ".."))
MOCKOUT_PATH = File.join(TRYOUTS_HOME, "bin", "mockout")

group "CLI"
command :mockout, MOCKOUT_PATH

tryout "Mockouts", :cli do
  
  # This fails. Rye problem?
  dream :class, Rye::Rap
  dream []
  drill "No args"
  
  dream ["One line of content"]
  drill "can echo single argument", :echo, "One line of content"
  
  dream ["Two lines", "of content"]
  drill "can echo single argument with line break", :echo, "Two lines#{$/}of content"
  
  dream :grep, /UTC/
  drill "can display date", :date
  
  dream []
  drill "can be quiet", :q, :test
  
  dream ["PASS"]
  drill "can execute via a block" do
    mockout :test, :p
  end
  
  dream :match, /\d+\.\d+\.\d+\.\d+/
  drill "can execute a block of commands" do
    ret = rudy :q, :myaddress, :e
    ret.first
  end
  
end


