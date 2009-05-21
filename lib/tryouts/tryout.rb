
class Tryouts::Tryout
  
    # The name of this tryout
  attr_reader :name
  
    # A Hash of Dream objects for this Tryout. The keys are drill names. 
  attr_accessor :dreams
  
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
    @dreams = {}
  end
  
  ## ---------------------------------------  EXTERNAL API  -----
  
  # Populate this Tryout from a block. The block should contain calls to 
  # the external DSL methods: dream, drill, xdrill
  def from_block(b, &inline)
    instance_eval &b
  end
  
  # Execute all Drill objects
  def run
    puts Tryouts::TRYOUT_MSG % @name
    @drills.each do |drill|
      drill.run   # returns true or false
    end
  end
  
  # Prints error output. If there are no errors, it prints nothing. 
  def report
    return if success?
    puts $/, "ERRORS:"
    @drills.each do |drill|
      next if drill.success?
      puts Tryouts::DRILL_MSG % drill.name
      if drill.reality.rcode < 0
        puts '%24s' % drill.reality.emsg 
        next
      end
      drill.discrepency.each do |d|
        if d == 'nodream'
          puts '%24s' % "[nodream]"
          next
        end
        puts '%24s: %s vs %s' % [d, drill.dream.send(d), drill.reality.send(d)]
      end
    end
  end
  
  # Did every Tryout finish successfully?
  def success?
    # Returns true only when every Tryout result returns true
    !(@drills.collect { |r| r.success? }.member?(false))
  end
  
  # Add a Drill object to the list for this Tryout. If there is a dream
  # defined with the same name as the Drill, that dream will be given to
  # the Drill before its added to the list. 
  def add_drill(d)
    d.add_dream @dreams[d.name] if !@dreams.nil? && @dreams.has_key?(d.name)
    drills << d if d.is_a?(Tryouts::Drill)
  end
  
  
  ## ---------------------------------------  EXTERNAL DSL  -----
  
  # Add or overwrite the entry in +@dreams+ for the drill named +name+. 
  # +output+, +rcode+, and +emsg+ are values appropriate for a Dream object.
  def dream(name, output, rcode=0, emsg=nil)
    dream = Tryouts::Drill::Dream.new
    output = [output] unless output.is_a?(Array)
    dream.output, dream.rcode, dream.emsg = output, rcode, emsg
    @dreams[name] = dream
  end
  
  # Create and add a Drill object to the list for this Tryout
  # +name+ is the name of the drill. 
  # +args+ is sent directly to the Drill class. The values are specific on the Sergeant.
  def drill(name, *args, &b)
    drill = Tryouts::Drill.new(name, @dtype, @command, *args, &b)
    add_drill drill
  end
  def xdrill(*args, &b); end # ignore calls to xdrill
end