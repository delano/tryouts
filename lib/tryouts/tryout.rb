
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
  
    # A block to executed one time before starting the drills
  attr_reader :before
    # A block to executed one time after the drills
  attr_reader :after
  
  @@valid_dtypes = [:cli, :api]
  
  # All :api Drills are run within this context (not used for :cli). 
  # Each Drill is executed in a new instance of this class. That means
  # instance variables are not carried through, but class variables are. 
  # The before and after blocks are also run in this context.
  class DrillContext; end
     
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
    DrillContext.new.instance_eval &before if before.is_a?(Proc)
    puts Tryouts::TRYOUT_MSG % @name
    @drills.each do |drill|
      drill.run(DrillContext.new)   # returns true or false
    end
    DrillContext.new.instance_eval &after if after.is_a?(Proc)
  end
  
  # Prints error output. If there are no errors, it prints nothing. 
  def report
    if success?
      puts $/, "All your dreams came true"
      return
    end
    puts $/, "ERRORS:"
    @drills.each do |drill|
      next if drill.success?
      puts Tryouts::DRILL_MSG % drill.name
      if drill.reality.rcode < 0
        puts '%24s' % drill.reality.emsg 
        next
      end
      
      if drill.dream
        drill.discrepency.each do |d|
          puts '%24s: %s' % ["dream #{d}", drill.dream.send(d).inspect]
          puts '%24s: %s' % ["reality #{d}", drill.reality.send(d).inspect]
        end
      else
        puts '%24s' % ["[nodream]"]
        if drill.reality.rcode > 0
          puts '%24s: %s' % ["rcode", drill.reality.rcode.inspect]
          puts '%24s: %s' % ["msg", drill.reality.emsg.inspect]
        end
      end
      
      if drill.reality.rcode > 0
        puts '%24s: %s' % ["backtrace", drill.reality.backtrace.inspect]
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
  
  # A block to executed one time before starting the drills
  def before(&block)
    return @before unless block
    @before = block
  end
  
  # A block to executed one time after the drills
  def after(&block)
    return @after unless block
    @after = block
  end
  
  # +name+ of the Drill associated to this Dream
  # +output+ A String or Array of expected output. A Dream object will be created using this value (optional)
  # +definition+ is a block which will be run on an instance of Dream
  #
  # NOTE: This method is DSL-only. It's not intended to be used in OO syntax. 
  def dream(name, output=nil, format=:string, rcode=0, emsg=nil, &definition)
    if output.nil?
      dobj = Tryouts::Drill::Dream.from_block definition
    else
      dobj = Tryouts::Drill::Dream.new(output)
      dobj.format, dobj.rcode, dobj.emsg = format, rcode, emsg
    end
    @dreams[name] = dobj
  end

  # Create and add a Drill object to the list for this Tryout
  # +name+ is the name of the drill. 
  # +args+ is sent directly to the Drill class. The values are specific on the Sergeant.
  def drill(name, *args, &b)
    args.unshift(@command) if @dtype == :cli
    drill = Tryouts::Drill.new(name, @dtype, *args, &b)
    add_drill drill
  end
  def xdrill(*args, &b); end # ignore calls to xdrill
  
  
  
  
  private
  
  # Convert every Hash of dream params into a Tryouts::Drill::Dream object
  def parse_dreams!
    if @dreams.kind_of?(Hash)
      #raise BadDreams, 'Not deep enough' unless @@dreams.deepest_point == 2
      @dreams.each_pair do |tname, drills|
        drills.each_pair do |dname, dream_params|
          next if dream_params.is_a?(Tryouts::Drill::Dream)
          dream = Tryouts::Drill::Dream.new
          dream_params.each_pair { |n,v| dream.send("#{n}=", v) }
          @dreams[tname][dname] = dream
        end
      end
    else
      raise BadDreams, 'Not a kind of Hash'
    end
  end
  
end