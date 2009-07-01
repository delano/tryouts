
TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), ".."))
MOCKOUT_PATH = File.join(TRYOUTS_HOME, "bin", "mockout")

group "CLI"
command :mockout, MOCKOUT_PATH

tryout "Mockouts", :cli do
  
  dream :class, Array
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
  
end


