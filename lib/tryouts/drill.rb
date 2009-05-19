

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
      
  def initialize(dtype, rcode, *drill_args, &drill)
    @dtype, @drill = dtype, drill
    @sergeant = hire_sergeant *drill_args
    
    @dream = Tryouts::Drill::Dream.new(rcode)
  end
  
  def hire_sergeant(*drill_args)
    if @dtype == :cli
      Tryouts::Drill::Sergeant::CLI.new(*drill_args)
    end
  end
  
  def run
    begin
      @reality = @sergeant.run @drill
    rescue => ex
      @reality = Tryouts::Drill::Reality.new
      @reality.exit_code = -2
      @reality.emsg, @reality.backtrace = ex.message, ex.backtrace
    end
  end
  
  def success?
    @dream == @reality
  end
  
  
end
