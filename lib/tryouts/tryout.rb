
class Tryouts
  
  # = Tryout
  #
  # A Tryout is a set of drills (each drill is a test). 
  #
  class Tryout
  
    # The name of this tryout
  attr_reader :name
    # A default value for Drill.dtype
  attr_reader :dtype
    # A block to executed one time before starting the drills
  attr_reader :setup
    # A block to executed one time before starting the drills
  attr_reader :clean
    # An Array of Drill objects
  attr_reader :drills
    # The number of dreams that came true (successful drills)
  attr_reader :passed
    # The number of dreams that did not come true (failed drills)
  attr_reader :failed
    # For drill type :cli, this is the name of the command to test. It
    # should be a valid method available to a Rye::Box object.
    # For drill type :api, this attribute is ignored. 
  attr_reader :command
    # A Hash of Dream objects for this Tryout. The keys are drill names. 
  attr_reader :dream_catcher
  
  @@valid_dtypes = [:cli, :api]
     
  def initialize(name, dtype, command=nil, *args)
    raise "Must supply command for dtype :cli" if dtype == :cli && command.nil?
    raise "#{dtype} is not a valid drill type" if !@@valid_dtypes.member?(dtype)
    @name, @dtype, @command = name, dtype, command
    @drills, @dream_catcher = [], []
    @passed, @failed = 0, 0
  end
  
  ## ---------------------------------------  EXTERNAL API  -----
  
  # Populate this Tryout from a block. The block should contain calls to 
  # the external DSL methods: dream, drill, xdrill
  def from_block(b=nil, &inline)
    runtime = b.nil? ? inline : b
    instance_eval &runtime
  end
  
  # Execute all Drill objects
  def run
    DrillContext.module_eval &setup if setup.is_a?(Proc)
    puts Tryouts::TRYOUT_MSG.bright % @name
    @drills.each do |drill|
      drill.run DrillContext.new
      note = @dream ? '' : '(nodream)'
      puts drill.success? ? "PASS".color(:green) : "FAIL #{note}".color(:red)
      puts "      #{drill.reality.output.inspect}" if Tryouts.verbose > 0
      if Tryouts.verbose > 1
        drill.reality.stash.each_pair do |n,v|
          puts '%14s: %s' % [n,v.inspect]
        end
      end
      drill.success? ? @passed += 1 : @failed += 1
    end
    DrillContext.module_eval &clean if clean.is_a?(Proc)
  end
  
  # Prints error output. If there are no errors, it prints nothing. 
  def report
    return true if success?
    failed = @drills.select { |d| !d.success? }
    failed.each_with_index do |drill,index|
      dream, reality = drill.dream, drill.reality
      title = ' %-59s' % %Q{ERROR #{index+1}/#{failed.size} "#{drill.name}"}
      puts $/, ' ' << title.color(:red).att(:reverse)
      
      if dream
        puts '%12s: %s' % [ "expected", dream.output.inspect]
        puts '%12s: %s' % ["returned", reality.output.inspect]
        unless reality.error.nil?
          puts '%12s: %s' % ["error", reality.error.inspect]
        end
        unless reality.trace.nil?
          puts '%12s: %s' % ["trace", reality.trace.join($/ + ' '*14)]
          puts
        end
      else
        puts '%12s: %s' % ["expected", "[nodream]"]
        puts '%12s: %s' % ["returned", reality.output.inspect]
      end
      
    end
    false
  end
  
  # Did every Tryout finish successfully?
  def success?
    return @success unless @success.nil?
    # Returns true only when every Tryout result returns true
    @success = !(@drills.collect { |r| r.success? }.member?(false))
  end
  
  # Add a Drill object to the list for this Tryout. If there is one or
  # more dreams in +@dream_catcher+, it will be added to drill +d+. 
  def add_drill(d)
    unless @dream_catcher.empty?
      d.add_dream @dream_catcher.first
      @dream_catcher.clear
    end
    drills << d
    d
  end
  
  ## ---------------------------------------  EXTERNAL DSL  -----
  
  # A block to executed one time _before_ starting the drills
  def setup(&block)
    return @setup unless block
    @setup = block
  end
  
  # A block to executed one time _after_ the drills
  def clean(&block)
    return @clean unless block
    @clean = block
  end
  
  # Create and add a Drill object to the list for this Tryout
  # +name+ is the name of the drill. 
  # +args+ is sent directly to the Drill class. The values are specific on the Sergeant.
  def drill(dname, *args, &definition)
    raise "Empty drill name (#{@name})" if dname.nil? || dname.empty?
    if definition.nil?
      drill = Tryouts::Drill.new(dname, @dtype, :output => args.first)
    else
      drill = Tryouts::Drill.new(dname, @dtype, args.first, &definition)
    end
    self.add_drill drill
  end
  # A quick way to comment out a drill
  def xdrill(*args, &b); end # ignore calls to xdrill
  
  
  #
  # NOTE: This method is DSL-only. It's not intended to be used in OO syntax. 
  def dream(*args, &definition) 
    if args.empty?
      dobj = Tryouts::Drill::Dream.from_block definition
    else
      if args.size == 1
        dobj = Tryouts::Drill::Dream.new(args.shift)    # dream 'OUTPUT'
      else
        dobj = Tryouts::Drill::Dream.new(*args.reverse) # dream :form, 'OUTPUT'
      end
    end
    @dream_catcher << dobj
    dobj
  end
  # A quick way to comment out a dream
  def xdream(*args, &b); end
  
end; end