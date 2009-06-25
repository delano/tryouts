

class Tryouts
  
  # = Drill
  # 
  # This class represents a drill. A drill is single test. 
  #
  class Drill
    
  require 'tryouts/drill/context'
  require 'tryouts/drill/response'
  require 'tryouts/drill/sergeant/cli'
  require 'tryouts/drill/sergeant/api'
  
  class NoSergeant < Tryouts::Exception; end
  class UnknownFormat < Tryouts::Exception; end
  
    # A symbol specifying the drill type. One of: :cli, :api
  attr_reader :dtype
    # The name of the drill. This should match the name used in the dreams file. 
  attr_reader :name
    # A Proc object which contains the drill logic. 
  attr_reader :drill
  
    # A Sergeant object which executes the drill
  attr_reader :sergeant
    # An Array of Dream objects (the expected output of the test)
  attr_reader :dreams
    # A Reality object (the actual output of the test)
  attr_reader :reality
      
  def initialize(name, dtype, *args, &drill)
    @name, @dtype, @drill, @skip = name, dtype, drill, false
    @dreams = []
    if @dtype == :cli
      @sergeant = Tryouts::Drill::Sergeant::CLI.new *args
    elsif @dtype == :api
      default_output = drill.nil? ? args.shift : nil
      @sergeant = Tryouts::Drill::Sergeant::API.new default_output
      @dreams << Tryouts::Drill::Dream.new(*args) unless args.empty?
    elsif @dtype == :skip
      @skip = true
    else
      raise NoSergeant, "Weird drill sergeant: #{@dtype}"
    end
    # For CLI drills, a block takes precedence over inline args. 
    # A block will contain multiple shell commands (see Rye::Box#batch)
    drill_args = [] if dtype == :cli && drill.is_a?(Proc)
    @reality = Tryouts::Drill::Reality.new
  end
  
  def skip?; @skip; end
  
  def run(context=nil)
    begin
      @reality = @sergeant.run @drill, context
      # Store the stash from the drill block
      @reality.stash = context.stash if context.respond_to? :stash
      # If the drill block returned true we assume success if there's no dream
      if @dreams.empty? && @reality.output == true
        @dreams << Tryouts::Drill::Dream.new
        @dreams.first.output = true
      end
    rescue => ex
      @reality.ecode, @reality.etype = -2, ex.class
      @reality.error, @reality.trace = ex.message, ex.backtrace
    end  
    self.success?
  end
  
  def success?
    return false if @dreams.empty? && @reality.output != true
    begin
      @dreams.each { |d| return false unless d == @reality }
    rescue => ex
      puts ex.message, ex.backtrace if Tryouts.debug?
      return false
    end
    true
  end
  
  
  def add_dream(d); @dreams << d; end
  def add_dreams(*d); @dreams += d; end
  
  private 
    
end; end
