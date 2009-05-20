

class Tryouts::Drill
  require 'tryouts/drill/response'
  require 'tryouts/drill/sergeant/cli'
    
    # A symbol specifying the drill type. One of: :cli
  attr_reader :dtype
    # The name of the drill. This should match the name used in the dreams file. 
  attr_reader :name
    # A Proc object which contains the drill logic. 
  attr_reader :drill
  
    # A Sergeant object which executes the drill
  attr_reader :sergeant
    # A Dream object
  attr_accessor :dream
    # A Reality object
  attr_reader :reality
      
  def initialize(name, dtype, *drill_args, &drill)
    @name, @dtype, @drill = name, dtype, drill
    @sergeant = hire_sergeant *drill_args
    # For CLI drills, a block takes precedence over inline args. 
    drill_args = [] if dtype == :cli && drill.is_a?(Proc)
  end
  
  def hire_sergeant(*drill_args)
    if @dtype == :cli
      Tryouts::Drill::Sergeant::CLI.new(*drill_args)
    end
  end
  
  def run
    begin
      print Tryouts::DRILL_MSG % @name
      @reality = @sergeant.run @drill
      puts self.success? ? "PASSED" : "FAILED"
    rescue => ex
      @reality = Tryouts::Drill::Reality.new
      @reality.rcode = -2
      @reality.emsg, @reality.backtrace = ex.message, ex.backtrace
    end
    self.success?
  end
  
  def success?
    @dream == @reality
  end
  
  
end
