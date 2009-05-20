TRYOUTS_HOME = File.join(File.dirname(__FILE__), '..')
TRYOUTS_LIB = File.join(TRYOUTS_HOME, 'lib')
$:.unshift TRYOUTS_LIB # Put our local lib in first place

require 'tryouts'

class RudyCLI < Tryouts
   
  command :mockout, File.join(TRYOUTS_HOME, 'bin', 'mockout')
  dreams File.join(TRYOUTS_HOME, 'tryouts', 'dreams')
  
  tryout "rudy myaddress" do
    drill 'noargs' do
      rudy :myaddress
    end
    drill 'internal only' do
      rudy :myaddress, :i
    end
    drill 'external only' do
      rudy :myaddress, :e
    end
    drill 'quiet' do
      rudy :q, :myaddress
    end
  end
  
  tryout "rudy myaddress" do
    command :rudy

    drill        'noargs',     :myaddress
    drill 'internal only',     :myaddress, :i
    drill 'external only',     :myaddress, :e
    drill         'quiet', :q, :myaddress
  end
  
  tryout "basic dsl syntax" do
    drill :mockout
    drill :mockout
  end
  
  
  tryout :myaddress do
    drill :rudy, :myaddress
    drill :rudy, :myaddress, :i
    drill :rudy, :myaddress, :e
    drill :rudy, :v, :myaddress
  end
  
end

Syntax.run
