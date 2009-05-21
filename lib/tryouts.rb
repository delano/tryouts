
require 'rubygems'
require 'ostruct'
require 'rye'
require 'yaml'
begin; require 'json'; rescue LoadError; end   # json may not be installed


class Tryouts
  class BadDreams < RuntimeError; end

  require 'tryouts/mixins'
  require 'tryouts/tryout'
  require 'tryouts/drill'
  
  TRYOUT_MSG = "\n     %s "
  DRILL_MSG  = ' %20s: '
  
    # An Array of Tryout objects
  @@tryouts = []
  
    # A Hash of Tryout names pointing to index values of @@tryouts
  @@tryouts_map = {}
  
    # A Hash of dreams for all tryouts in this class. The keys should
    # match the names of each tryout. The values are hashes will drill
    # names as keys and response 
  @@dreams = {}
  
    # A symbol representing the command taking part in tryout
  @@command = nil
  
  
  ## ----------------------------  EXTERNAL DSL  -----
  
  # Load dreams from a file, directory, or Hash.
  # Raises a Tryouts::BadDreams exception when something goes awry. 
  def self.dreams(dreams=nil, &definition)
    return @@dreams unless dreams
    if File.exists?(dreams)
      # If we're given a directory we'll build the filename using the class name
      dreams = find_dreams_file(dreams) if File.directory?(dreams)
      @@dreams = load_dreams_file dreams
    elsif dreams.kind_of?(Hash)
      @@dreams = dreams
    elsif dreams.kind_of?(String) && definition
      @@current_dream = dreams  # Used in Tryouts.dream
      @@dreams[@@current_dream] ||= {}
      # TODO: definition.call is returning the wrong value. It needs to return the dream hash for a tryout
      definition.call
    else
      raise BadDreams, dreams
    end
    @@dreams
  end
  
  # +name+ of the Drill associated to this Dream
  # +definition+ is a block which will be run on an instance of Dream
  def self.dream(name, &definition)
    @@dreams[@@current_dream][name] = Tryouts::Drill::Dream.from_block definition
  end
  
  # Add a shell command to Rye::Cmd and save the command name
  # in @@commands so it can be used as the default for drills
  def self.command(name, path=nil)
    return if name.nil?
    @@command = name.to_sym
    Rye::Cmd.module_eval do
      define_method(name) do |*args|
        cmd(path || name, *args)
      end
    end
  end

  # Create a new Tryout object and add it to the list for this Tryouts class. 
  # * +name+ is the name of the Tryout
  # * +type+ is the default drill type for the Tryout. One of: :cli, :api
  # * +command+ when type is :cli, this is the name of the Rye::Box method that we're testing. Otherwise ignored. 
  # * +b+ is a block definition for the Tryout. See Tryout#from_block
  def self.tryout(name, type=:cli, command=nil, &b)
    command ||= @@command if type == :cli
    to = Tryouts::Tryout.new(name, type, command)
    to.dreams = @@dreams[name] if @@dreams.has_key?(name)
    to.from_block b
    @@tryouts << to
    @@tryouts_map[name] = @@tryouts.size - 1  # WARNING: NOT THREAD SAFE
  end
  
  # Ignore a tryout
  def self.xtryout(name, &b)
  end
  
  def self.run
    puts "-"*60
    puts "Tryouts for #{self}"
    @@tryouts.each do |to|
      to.run
      to.report
    end
  end
  
  def self.report
    @@tryouts.each do |to|
      to.report
    end
  end
  
  ##---
  ## Is this wacky syntax useful for anything?
  ##    t2 :set .
  ##       run = "poop"
  ## def self.t2(*args)
  ##   OpenStruct.new
  ## end
  ##+++
  
  
 private 
   # Convert every Hash of dream params into a Tryouts::Drill::Dream object
   def self.parse_dreams
     if @@dreams.kind_of?(Hash)
       
       #raise BadDreams, 'Not deep enough' unless @@dreams.deepest_point == 2
       @@dreams.each_pair do |tname, drills|
         drills.each_pair do |dname, dream_params|
           next if dream_params.is_a?(Tryouts::Drill::Dream)
           dream = Tryouts::Drill::Dream.new
           dream_params.each_pair { |n,v| dream.send("#{n}=", v) }
           @@dreams[tname][dname] = dream
         end
       end
     else
       raise BadDreams, 'Not a kind of Hash'
     end
   end
   
   # Populate @@dreams with the content of the file +dpath+. 
   def self.load_dreams_file(dpath)
     type = File.extname dpath
     if type == ".yaml" || type == ".yml"
       @@dreams = YAML.load_file dpath
     elsif type == ".json" || type == ".js"
       @@dreams = JSON.load_file dpath
     elsif type == ".rb"
       @@dreams = class_eval File.read dpath
     else
       raise BadDreams, "Unknown kind of dream: #{dpath}"
     end
     parse_dreams
   end
   
   # Find a dreams file in the directory +dir+ based on the current class name.
   # The expected filename format is: classname_dreams.ext where "classname" is
   # the lowercase name of the Tryouts subclass and "ext" is one of: yaml, js, 
   # json, rb. 
   #
   #     e.g.
   #     Tryouts.find_dreams_file "dirpath"   # => dirpath/tryouts_dreams.rb
   #
   def self.find_dreams_file(dir)
     dpath = nil
     [:rb, :yaml].each do |ext|
       tmp = File.join(dir, "#{self.to_s.downcase}_dreams.#{ext}")
       if File.exists?(tmp)
         dpath = tmp
         break
       end
     end
     dpath
   end
 
end
