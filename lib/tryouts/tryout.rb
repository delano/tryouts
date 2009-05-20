
class Tryouts::Tryout
  
    # The name of this tryout
  attr_reader :name
  
    # An Array of Drill objects
  attr_reader :drills
  
    # A default value for Drill.dtype
  attr_reader :dtype
    # For drill type :cli, this is the name of the command to test. It
    # should be a valid method available to a Rye::Box object.
    # For drill type :api, this attribute is ignored. 
  attr_reader :command
  
  @@valid_dtypes = [:cli, :api]
  
  def initialize(name, dtype, command=nil, *args)
    raise "Must supply command for dtype :cli" if dtype == :cli && command.nil?
    raise "#{dtype} is not a valid drill type" if !@@valid_dtypes.member?(dtype)
    @name, @dtype, @command = name, dtype, command
    @drills = []
  end
  
  ## ---------------------------------------  EXTERNAL API  -----
  def from_block(b, &inline)
    instance_eval &b
  end
  
  def run
    puts Tryouts::TRYOUT_MSG % @name
    @drills.each do |drill|
      drill.run   # returns true or false
    end
  end
  
  def report
    return if success?
    @drills.each do |drill|
      next if drill.success?
      p drill.reality
    end
  end
  
  # Did every Tryout finish successfully?
  def success?
    # Returns true only when every Tryout result returns true
    !(@drills.collect { |r| r.success? }.member?(false))
  end
  
    
  def add_drill(d)
    drills << d if d.is_a?(Tryouts::Drill)
  end
  
  
  ## ---------------------------------------  EXTERNAL DSL  -----
  def drill(name, *args, &b)
    drill = Tryouts::Drill.new(name, @dtype, @command, *args, &b)
    add_drill drill
  end
  
end