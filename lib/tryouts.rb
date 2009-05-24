
require 'rubygems'
require 'ostruct'
require 'rye'
require 'yaml'
begin; require 'json'; rescue LoadError; end   # json may not be installed

GYMNASIUM_HOME = File.join(Dir.pwd, 'tryouts')
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
  class BadDreams < Exception; end
  
  VERSION = "0.5"
  
  require 'tryouts/mixins'
  require 'tryouts/tryout'
  require 'tryouts/drill'
  
  TRYOUT_MSG = "\n     %s "
  DRILL_MSG  = ' %20s: '
  
    # An Hash of Tryouts instances stored under the name of the Tryouts subclass. 
  @@instances = {}
    # The most recent tryouts name specified in the DSL
  @@instance_pointer = nil
  
    # The name of this group of Tryout objects
  attr_accessor :group
    # An Array of Tryout objects
  attr_accessor :tryouts
    # A Hash of Tryout names pointing to index values of :tryouts
  attr_accessor :map
    # A Symbol representing the command taking part in the tryouts. For @dtype :cli only. 
  attr_accessor :command
    # A Symbol representing the name of the library taking part in the tryouts. For @dtype :api only.
  attr_accessor :library
    # A Symbol representing the default drill type. One of: :cli, :api
  attr_accessor :dtype
  
    # A Hash of dreams for all tryouts in this class. The keys should
    # match the names of each tryout. The values are hashes will drill
    # names as keys and response
  attr_accessor :dreams
    # The name of the most recent dreams group (see self.dream)
  attr_accessor :dream_pointer
  
  # Returns +@@instances+
  def self.instances; @@instances; end

  def initialize(group=nil)
    @group = group || "Default Group"
    @tryouts = []
    @map = {}
    @command = nil
    @dtype = :cli
    @dreams = {}
    @dream_pointer = nil
  end
  
  # Populate this Tryouts from a block. The block should contain calls to 
  # the external DSL methods: tryout, command, dreams
  def from_block(b, &inline)
    instance_eval &b
  end
  
  # Execute Tryout#report for each Tryout in +@tryouts+
  def report; @tryouts.each { |to| to.report }; end
  
  # Execute Tryout#run for each Tryout in +@tryouts+
  def run; @tryouts.each { |to| to.run }; end
  
  # Add a shell command to Rye::Cmd and save the command name
  # in @@commands so it can be used as the default for drills
  def command(name=nil, path=nil)
    return @command if name.nil?
    @command = name.to_sym
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
    @@instances[ @@instance_pointer ].command(*args)
  end
  
  
  # Require +name+. If +path+ is supplied, it will "require path". 
  # * +name+ The name of the library in question (required). Stored as a Symbol to +@library+.
  # * +path+ The path to the library (optional). Use this if you want to load
  # a specific copy of the library. Otherwise, it loads from the system path
  def library(name=nil, path=nil)
    return @library if name.nil?
    @library = name.to_sym
    require path.nil? ? @library : path
  end
  # Calls Tryouts#library on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.library(*args)
    @@instances[ @@instance_pointer ].library(*args)
  end
  
  def group(name=nil)
    return @group if name.nil?
    @group = name unless name.nil?
    # Preload dreams if possible
    dfile = self.class.find_dreams_file(GYMNASIUM_HOME, @group)
    self.load_dreams_file(dfile) if dfile
    @group
  end
  # Raises a Tryouts::Exception. +group+ is not support in the standalone syntax
  # because the group name is take from the name of the class. See inherited. 
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.group(*args)
    raise "Group is already set: #{@@instances[ @@instance_pointer ].group}"
  end
  
  # Create a new Tryout object and add it to the list for this Tryouts class. 
  # * +name+ is the name of the Tryout
  # * +type+ is the default drill type for the Tryout. One of: :cli, :api
  # * +command+ when type is :cli, this is the name of the Rye::Box method that we're testing. Otherwise ignored. 
  # * +b+ is a block definition for the Tryout. See Tryout#from_block
  #
  # NOTE: This is a DSL-only method and is not intended for OO use. 
  def tryout(name, type=nil, command=nil, &block)
    return if name.nil?
    type ||= @dtype
    command ||= @command if type == :cli
    to = Tryouts::Tryout.new(name, type, command)
    # Populate the dreams if they've already been loaded
    to.dreams = @dreams[name] if @dreams.has_key?(name)
    # Process the rest of the DSL
    to.from_block block if block
    @tryouts << to
    @map[name] = @tryouts.size - 1
    to
  end
  # Calls Tryouts#tryout on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.tryout(*args, &block)
    @@instances[ @@instance_pointer ].tryout(*args, &block)
  end
  
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: This is a DSL-only method and is not intended for OO use.
  def xtryout(*args, &block); end
  # This method does nothing. It provides a quick way to disable a tryout.
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.xtryout(*args, &block); end
  
  # Load dreams from a file, or Hash.
  # Raises a Tryouts::BadDreams exception when something goes awry. 
  #
  # This method is used in two ways:
  # * In the dreams file DSL
  # * As a getter method on a Tryout object
  def dreams(group=nil, &definition)
    return @dreams unless group
    if File.exists?(group)
      dfile = group
      # If we're given a directory we'll build the filename using the class name
      dfile = self.class.find_dreams_file(group) if File.directory?(group)
      raise BadDreams, "Cannot find dreams file (#{group})" unless dfile
      @dreams = load_dreams_file dfile
    elsif group.kind_of?(Hash)
      @dreams = group
    elsif group.kind_of?(String) && definition  
      @dream_pointer = group  # Used in Tryouts.dream
      @dreams[ @dream_pointer ] ||= {}
      definition.call
    else
      raise BadDreams, group
    end
    @dreams
  end
  # Without arguments, returns a Hash of all known dreams.
  # With arguments, it calls Tryouts#dreams on the current instance of Tryouts. 
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.dreams(*args, &block)
    if args.empty? && block.nil?
      dreams = {}
      @@instances.each_pair do |name,inst|
        dreams[name] = inst.dreams
      end
      return dreams
    else
      @@instances[ @@instance_pointer ].dreams(*args, &block)
    end
  end
  
  # +name+ of the Drill associated to this Dream
  # +output+ A String or Array of expected output. A Dream object will be created using this value (optional)
  # +definition+ is a block which will be run on an instance of Dream
  #
  #
  # NOTE: This method is DSL-only. It's not intended to be used in OO syntax. 
  def dream(name, output=nil, format=:string, rcode=0, emsg=nil, &definition)
    if output.nil?
      dobj = Tryouts::Drill::Dream.from_block definition
    else
      dobj = Tryouts::Drill::Dream.new(output)
      dobj.format, dobj.rcode, dobj.emsg = format, rcode, emsg
    end
    @dreams[@dream_pointer][name] = dobj
  end
  # Calls Tryouts#dream on the current instance of Tryouts
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.dream(*args, &block)
    @@instances[ @@instance_pointer ].dream(*args, &block)
  end
  
  # Populate @@dreams with the content of the file +dpath+. 
  #
  # NOTE: this is an OO syntax method
  def load_dreams_file(dpath)
    type = File.extname dpath
    if type == ".yaml" || type == ".yml"
      @dreams = YAML.load_file dpath
    elsif type == ".json" || type == ".js"
      @dreams = JSON.load_file dpath
    elsif type == ".rb"
      @dreams = instance_eval File.read(dpath)
    else
      raise BadDreams, "Unknown kind of dream: #{dpath}"
    end
    @dreams
  end
  
  # Parse a +_tryouts.rb+ file. See Tryouts::CLI::Run for an example. 
  #
  # NOTE: this is an OO syntax method
  def self.parse_file(fpath)
    raise "No such file: #{fpath}" unless File.exists?(fpath)
    to = Tryouts.new
    to.instance_eval(File.read(fpath), fpath)
    @@instance_pointer = to.group
    @@instances[ @@instance_pointer ] = to
  end
  
  # Run all Tryout objects in +@tryouts+
  #
  # NOTE: this is an OO syntax method
  def self.run
    @@instances.each_pair do |group, inst|
      puts "-"*60
      puts "Tryouts for #{group}"
      inst.tryouts.each do |to|
        to.run
        to.report
        STDOUT.flush
      end
    end
  end
  
  # Called when a new class inherits from Tryouts. This creates a new instance
  # of Tryouts, sets group to the name of the new class, and adds the instance
  # to +@@instances+. 
  #
  # NOTE: this is a standalone DSL-syntax method.
  def self.inherited(klass)
    to = Tryouts.new
    to.group = klass
    @@instance_pointer = to.group
    @@instances[ @@instance_pointer ] = to
  end
  
  
  ##---
  ## Is this wacky syntax useful for anything?
  ##    t2 :set .
  ##       run = "poop"
  ## def self.t2(*args)
  ##   OpenStruct.new
  ## end
  ##+++
  
  # Find a dreams file in the directory +dir+ based on the current group name.
  # The expected filename format is: groupname_dreams.ext where "groupname" is
  # the lowercase name of the Tryouts group (spaces removed) and "ext" is one 
  # of: yaml, js, json, rb. 
  #
  #     e.g.
  #     Tryouts.find_dreams_file "dirpath"   # => dirpath/tryouts_dreams.rb
  #
  def self.find_dreams_file(dir, group=nil)
    dpath = nil
    group ||= @@instance_pointer
    group = group.to_s.downcase.tr(' ', '')
    [:rb, :yaml].each do |ext|
      tmp = File.join(dir, "#{group}_dreams.#{ext}")
      if File.exists?(tmp)
        dpath = tmp
        break
      end
    end
    dpath
  end
  

end
