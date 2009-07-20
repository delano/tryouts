
require 'time'
require 'attic'
require 'sysinfo'
require 'digest/sha1'
require 'ostruct'
require 'yaml'

## NOTE: Don't require rye here so
## we can still run tryouts on the
## development version. 

begin; require 'json'; rescue LoadError; end   # json may not be installed

GYMNASIUM_HOME = File.join(Dir.pwd, '{tryouts,try}')  ## also check try (for rye)
GYMNASIUM_GLOB = File.join(GYMNASIUM_HOME, '**', '*_tryouts.rb')


# = Tryouts
# 
# This class has three purposes:
# * It represents the Tryouts object which is a group of Tryout objects. 
# * The tryouts and dreams DSLs are executed within its namespace. In general the 
#   class methods are the handlers for the DSL syntax (some instance getter methods 
#   are modified to support DSL syntax by acting like setters when given arguments)
# * It stores all known instances of Tryouts objects in a class variable @@instances.
#
# ==== Are you ready to run some drills?
#
# May all your dreams come true!
#
class Tryouts
  # = Exception
  # A generic exception which all other Tryouts exceptions inherit from.
  class Exception < RuntimeError; end
  # = BadDreams
  # Raised when there is a problem loading or parsing a Tryouts::Drill::Dream object
  class BadDream < Tryouts::Exception; end
  class TooManyArgs < Tryouts::Exception; end
  class NoDrillType < Tryouts::Exception
    attr_accessor :tname
    def initialize(t); @tname = t; end
    def message
      vdt = Tryouts::Drill.valid_dtypes
      "Tryout '#{@tname}' has no drill type. Should be: #{vdt.join(', ')}"
    end
  end
    
  VERSION = "0.8.3"
  
  require 'tryouts/mixins'
  require 'tryouts/tryout'
  require 'tryouts/drill'
  require 'tryouts/stats'
  
  require 'tryouts/orderedhash'
  HASH_TYPE = (RUBY_VERSION =~ /1.9/) ? ::Hash : Tryouts::OrderedHash

    # An Array of +_tryouts.rb+ file paths that have been loaded.
  @@loaded_files = []
    # An Hash of Tryouts instances stored under the name of the Tryouts subclass. 
  @@instances = HASH_TYPE.new
    # An instance of SysInfo
  @@sysinfo = SysInfo.new
  
  @@debug = false
  @@verbose = 0
    # This will be true if any error occurred during any of the drills or parsing. 
  @@failed = false  
  
  def self.debug?; @@debug; end
  def self.enable_debug; @@debug = true; end
  def self.disable_debug; @@debug = false; end
  
  def self.verbose; @@verbose; end
  def self.verbose=(v); @@verbose = (v == true) ? 1 : v; end
  
  def self.failed?; @@failed; end
  def self.failed=(v); @@failed = v; end
  
  # Returns +@@instances+
  def self.instances; @@instances; end
  # Returns +@@sysinfo+
  def self.sysinfo;   @@sysinfo;   end
  
    # The name of this group of Tryout objects
  attr_accessor :group
    # A Symbol representing the default drill type. One of: :cli, :api
  attr_accessor :dtype
    # An Array of file paths which populated this instance of Tryouts
  attr_accessor :paths
    # An Array of Tryout objects
  attr_accessor :tryouts
    # A Symbol representing the command taking part in the tryouts. For @dtype :cli only. 
  attr_accessor :command
    # A Symbol representing the name of the library taking part in the tryouts. For @dtype :api only.
  attr_accessor :library
    # An Array of exceptions that were raised during the tryouts that were not captured by a drill.
  attr_reader :errors
  
  def initialize(group=nil)
    @group = group || "Default Group"
    @tryouts = HASH_TYPE.new
    @paths, @errors = [], []
    @command = nil
  end
  
  # Populate this Tryouts from a block. The block should contain calls to 
  # the external DSL methods: tryout, command, library, group
  def from_block(b, &inline)
    instance_eval &b
  end
  
  # Execute Tryout#report for each Tryout in +@tryouts+
  def report
    successes = []
    @tryouts.each_pair { |n,to| successes << to.report }
    puts $/, "All your dreams came true" unless successes.member?(false)
  end
  
  # Execute Tryout#run for each Tryout in +@tryouts+
  def run; @tryouts.each_pair { |n,to| to.run }; end
  
  # Add a shell command to Rye::Cmd and save the command name
  # in @@commands so it can be used as the default for drills
  def command(name=nil, path=nil)
    return @command if name.nil?
    require 'rye'
    @command = name.to_sym
    @dtype = :cli
    Rye::Cmd.module_eval do
      define_method(name) do |*args|
        cmd(path || name, *args)
      end
    end
    @command
  end
  # Calls Tryouts#command on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method. 
  def self.command(*args)
    @@instances.last.command(*args)
  end
  
  # Require +name+. If +path+ is supplied, it will "require path". 
  # * +name+ The name of the library in question (required). Stored as a Symbol to +@library+.
  # * +path+ Add a path to the front of $LOAD_PATH (optional). Use this if you want to load
  #   a specific copy of the library. Otherwise, it loads from the system path. If the path 
  #   in specified in multiple arguments they are joined and expanded.
  #
  #    library '/an/absolute/path'
  #    library __FILE__, '..', 'lib'
  #
  def library(name=nil, *path)
    return @library if name.nil?
    @library, @dtype = name.to_sym, :api
    path = File.expand_path(File.join(*path))
    $LOAD_PATH.unshift path unless path.nil?
    begin
      require @library.to_s
    rescue LoadError => ex
      newex = Tryouts::Exception.new(ex.message)
      trace = ex.backtrace
      trace.unshift @paths.last
      newex.set_backtrace trace
      @errors << newex
      Tryouts.failed = true
    rescue SyntaxError, Exception, TypeError, 
           RuntimeError, NoMethodError, NameError => ex
      @errors << ex
      Tryouts.failed = true
    end
  end
  # Calls Tryouts#library on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.library(*args)
    @@instances.last.library(*args)
  end
  
  def group(name=nil)
    return @group if name.nil?
    @group = name unless name.nil?
    @group
  end
  # Raises a Tryouts::Exception. +group+ is not support in the standalone syntax
  # because the group name is taken from the name of the class. See inherited. 
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.group(*args)
    raise "Group is already set: #{@@instances.last.group}"
  end
  
  # Create a new Tryout object and add it to the list for this Tryouts class. 
  # * +name+ is the name of the Tryout
  # * +dtype+ is the default drill type for the Tryout.
  # * +command+ when type is :cli, this is the name of the Rye::Box method that we're testing. Otherwise ignored. 
  # * +b+ is a block definition for the Tryout. See Tryout#from_block
  #
  # NOTE: This is a DSL-only method and is not intended for OO use. 
  def tryout(name, dtype=nil, command=nil, &block)
    return if name.nil?
    dtype ||= @dtype
    command ||= @command if dtype == :cli
    
    raise NoDrillType, name if dtype.nil?
    
    to = find_tryout(name, dtype)
    if to.nil?
      to = Tryouts::Tryout.new(name, dtype, command)
      @tryouts[name] = to
    end
    
    # Process the rest of the DSL
    begin
      to.from_block block if block
    rescue SyntaxError, LoadError, Exception, TypeError,
           RuntimeError, NoMethodError, NameError => ex
      @errors << ex
      Tryouts.failed = true
    end
    to
  end
  # Calls Tryouts#tryout on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.tryout(*args, &block)
    @@instances.last.tryout(*args, &block)
  end

  # Find matching Tryout objects by +name+ and filter by 
  # +dtype+ if specified. Returns a Tryout object or nil.
  def find_tryout(name, dtype=nil)
    by_name = @tryouts.values.select { |t| t.name == name }
    by_name = by_name.select { |t| t.dtype == dtype } if dtype
    by_name.first  # by_name is an Array. We just want the Object. 
  end
  
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: This is a DSL-only method and is not intended for OO use.
  def xtryout(*args, &block); end
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.xtryout(*args, &block); end
  
  # Returns +@tryouts+.
  #
  # Also acts as a stub for Tryouts#tryout in case someone 
  # specifies "tryouts 'name' do ..." in the DSL. 
  def tryouts(*args, &block)
    return tryout(*args, &block) unless args.empty?
    @tryouts
  end
  # An alias for Tryouts.tryout. 
  def self.tryouts(*args, &block)
    tryout(args, &block)
  end
  
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: This is a DSL-only method and is not intended for OO use.
  def xtryouts(*args, &block); end
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.xtryouts(*args, &block); end
  
  
  # Parse a +_tryouts.rb+ file. See Tryouts::CLI::Run for an example. 
  #
  # NOTE: this is an OO syntax method
  def self.parse_file(fpath)
    raise "No such file: #{fpath}" unless File.exists?(fpath)
    file_content = File.read(fpath)
    to = Tryouts.new
    begin
      to.paths << fpath
      to.instance_eval file_content, fpath
      # After parsing the DSL, we'll know the group name.
      # If a Tryouts object already exists for that group
      # we'll use that instead and re-parse the DSL. 
      if @@instances.has_key? to.group
        to = @@instances[to.group]
        to.instance_eval file_content, fpath
      end
    rescue SyntaxError, LoadError, Exception, TypeError,
           RuntimeError, NoMethodError, NameError => ex
      to.errors << ex
      Tryouts.failed = true
      # It's helpful to display the group name
      file_content.match(/^group (.+?)$/) do |x,t|
        # We use eval as a quick cheat so we don't have
        # to parse all the various kinds of quotes.
        to.group = eval x.captures.first
      end
    end
    @@instances[to.group] = to
    to
  end
  
  # Run all Tryout objects in +@tryouts+
  #
  # NOTE: this is an OO syntax method
  def self.run
    @@instances.each_pair do |group, inst|
      inst.tryouts.each_pair do |name,to|
        to.run
        to.report
      end
    end
  end
  
  # Called when a new class inherits from Tryouts. This creates a new instance
  # of Tryouts, sets group to the name of the new class, and adds the instance
  # to +@@instances+. 
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.inherited(klass)
    to = @@instances[ klass ]
    to ||= Tryouts.new
    to.paths << __FILE__
    to.group = klass
    @@instances[to.group] = to
  end
  
  
  ##---
  ## Is this wacky syntax useful for anything?
  ##    t2 :set .
  ##       run = "poop"
  ## def self.t2(*args)
  ##   OpenStruct.new
  ## end
  ##+++
  

end
