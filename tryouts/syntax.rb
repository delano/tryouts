TRYOUTS_HOME = File.join(File.dirname(__FILE__), '..')
TRYOUTS_LIB = File.join(TRYOUTS_HOME, 'lib')
$:.unshift TRYOUTS_LIB # Put our local lib in first place

require 'tryouts'

class RudyCLI < Tryouts
  command :rudy, "/bin/ls"
  
  tryout "display machines" do
    drill 0, 'localhost' do
      rudy2 :V
    end
  end

end

RudyCLI.run
