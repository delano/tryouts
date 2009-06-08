
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
  attr_accessor :dreams
  
  @@valid_dtypes = [:cli, :api]
  
  # All :api Drills are run within this context (not used for :cli). 
  # Each Drill is executed in a new instance of this class. That means
  # instance variables are not carried through, but class variables are. 
  # The before and after blocks are also run in this context.
  class DrillContext
      # An ordered Hash of stashed objects. 
    attr_writer :stash
      # A value used as the dream output that will overwrite a predefined dream
    attr_writer :dream
    attr_writer :format
    attr_writer :rcode
    attr_writer :emsg
    attr_writer :output
    
    def initialize; @stash = Tryouts::HASH_TYPE.new; @has_dream = false; end
    
    # Set to to true by DrillContext#dream
    def has_dream?; @has_dream; end
    
    # If called with no arguments, returns +@stash+. 
    # If called with arguments, it will add a new value to the +@stash+
    # and return the new value.  e.g.
    #
    #     stash :name, 'some value'   # => 'some value'
    #
    def stash(*args)
      return @stash if args.empty?
      @stash[args[0]] = args[1] 
      args[1] 
    end
    
    # If called with no arguments, returns +@dream+. 
    # If called with one argument, it will overwrite +@dream+ with the
    # first element. If called with two arguments, it will check if
    # the second argument is a Symbol or Fixnum. If it's a Symbol it 
    # will assume it's +@format+. If it's a Fixnum, it will assume 
    # it's +@rcode+. If there's a there's a third argument and it's a
    # Fixnum, it's assumed to be +@rcode+. In all cases, this method 
    # returns the value of +@dream+. e.g.
    #
    #     dream 'some value'         # => 'some value'
    #     dream :val1, :class, 1     # => :val1
    #
    def dream(*args)
      return @dream if args.empty?
      @has_dream = true
      @dream = args.shift
      @format = args.shift if args.first.is_a? Symbol
      @rcode = args.shift if args.first.is_a? Fixnum
      @emsg = args.shift if args.first.is_a? String
    end
    
    def output(*args); return @output if args.empty?; @output = args.first; end
    def format(*args); return @format if args.empty?; @format = args.first; end
    def rcode(*args); return @rcode if args.empty?; @rcode = args.first; end
    def emsg(*args); return @emsg if args.empty?; @emsg = args.first; end
    
  end
     
  def initialize(name, dtype, command=nil, *args)
    raise "Must supply command for dtype :cli" if dtype == :cli && command.nil?
    raise "#{dtype} is not a valid drill type" if !@@valid_dtypes.member?(dtype)
    @name, @dtype, @command = name, dtype, command
    @drills, @dreams = [], {}
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
    update_drills!   # Ensure all drills have all known dreams
    DrillContext.module_eval &setup if setup.is_a?(Proc)
    puts Tryouts::TRYOUT_MSG.bright % @name
    @drills.each do |drill|
      drill.run(DrillContext.new)      # Returns true or false
      drill.reality.stash.each_pair do |n,v|
        puts '%14s: %s' % [n,v.inspect]
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
      title = ' %-59s' % %Q{ERROR #{index+1}/#{failed.size} "#{drill.name}"}
      puts $/, ' ' << title.color(:red).att(:reverse)
      
      if drill.dream
        puts '%24s: %s (expected %s)' % ["response code", drill.reality.rcode, drill.dream.rcode]
        puts '%24s: %s' % ["expected output", drill.dream.output.inspect]
        puts '%24s: %s' % ["actual output", drill.reality.output.inspect]
        if drill.reality.emsg || (drill.reality.emsg != drill.dream.emsg)
          puts '%24s: %s' % ["expected error msg", drill.dream.emsg.inspect]
            puts '%24s: %s' % ["actual error msg", drill.reality.emsg.inspect]
        end
        
        if drill.reality.rcode > 0
          puts '%24s: ' % ["backtrace"]
          puts drill.reality.backtrace, $/
        end
      else
        puts '%24s: %s' % ["expected output", "[nodream]"]
        puts '%24s: %s' % ["actual output", drill.reality.output.inspect]
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
  
  # Add a Drill object to the list for this Tryout. If there is a dream
  # defined with the same name as the Drill, that dream will be given to
  # the Drill before its added to the list. 
  def add_drill(d)
    d.add_dream @dreams[d.name] if !@dreams.nil? && @dreams.has_key?(d.name)
    drills << d if d.is_a?(Tryouts::Drill)
    d
  end
  
  # Goes through the list of Drill objects (@drills) and gives each 
  # one its associated Dream object (if available). 
  # 
  # This method is called before Tryout#run, but is only necessary in  
  # the case where dreams where loaded after the drills were defined. 
  def update_drills!
    return if @dreams.nil?
    @drills.each do |drill|
      next unless @dreams.has_key?(drill.name)
      drill.add_dream @dreams[drill.name]
    end
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
    args.unshift(@command) if @dtype == :cli
    drill = Tryouts::Drill.new(dname, @dtype, *args, &definition)
    add_drill drill
  end
  # A quick way to comment out a drill
  def xdrill(*args, &b); end # ignore calls to xdrill
  
  # +name+ of the Drill associated to this Dream
  # +output+ A String or Array of expected output. A Dream object will be created using this value (optional)
  # +definition+ is a block which will be run on an instance of Dream
  #
  # NOTE: This method is DSL-only. It's not intended to be used in OO syntax. 
  def dream(dname, output=nil, format=nil, rcode=0, emsg=nil, &definition) 
    raise "Empty dream name (#{@name})" if dname.nil? || dname.empty?
    if output.nil?
      raise "No output or block for '#{dname}' (#{@name})" if definition.nil?
      dobj = Tryouts::Drill::Dream.from_block definition
    else
      dobj = Tryouts::Drill::Dream.new(output)
      dobj.format, dobj.rcode, dobj.emsg = format, rcode, emsg
    end
    @dreams[dname] = dobj
    dobj
  end
  # A quick way to comment out a dream
  def xdream(*args, &b); end
  
end; end