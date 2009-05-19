

class Tryouts::Drill
  require 'tryouts/drill/response'
  require 'tryouts/drill/sergeant/cli'
    
    # A symbol specifying the drill type. One of: :cli
  attr_reader :dtype

    # A Proc object which contains the drill logic. 
  attr_reader :drill
    # A Sergeant object which executes the drill
  attr_reader :sergeant

    # A Dream object
  attr_reader :dream
    # A Reality object
  attr_reader :reality
      
  def initialize(dtype, rcode, *args, &drill)
    @dtype, @drill = dtype, drill
    @sergeant = hire_sergeant *args
    
    @dream = Tryouts::Drill::Dream.new(rcode)
  end
  
  def hire_sergeant(*args)
    if @dtype == :cli
      Tryouts::Drill::Sergeant::CLI.new(*args)
    end
  end
  
  def run
    @reality = @sergeant.run @drill
  end
end
