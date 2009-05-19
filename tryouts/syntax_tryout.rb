TRYOUTS_HOME = File.join(File.dirname(__FILE__), '..')
TRYOUTS_LIB = File.join(TRYOUTS_HOME, 'lib')
$:.unshift TRYOUTS_LIB # Put our local lib in first place

require 'tryouts'

class Syntax < Tryouts
  command :rudy
  dreams File.join(TRYOUTS_HOME, 'tryouts', 'syntax.yaml')
  tryout "display machines" do
    drill 'localhost' do
      rudy 
    end
  end

end

Syntax.run
