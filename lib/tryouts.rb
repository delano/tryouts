
require 'rubygems'
require 'ostruct'
require 'rye'
require 'yaml'
begin; require 'json'; rescue LoadError; end   # json may not be installed


class Tryouts
  class BadDreams < RuntimeError; end
  
  require 'tryouts/tryout'
  require 'tryouts/drill'
  
  TRYOUT_MSG = "\n%16s "
  DRILL_MSG  = '%18s: '
  
    # An Array of Tryout objects
  @@tryouts = []
  
    # A Hash of dreams
  @@dreams = {}
  
    # A symbol representing the command taking part in tryout
  @@command = nil
  
  ## ----------------------------  EXTERNAL DSL  -----
  def self.dreams(d=nil)
    return @@dreams unless d
    
    if File.exists?(d)
      type = File.extname d
      if type == ".yaml" || type == ".yml"
        @@dreams = YAML.load_file d
      elsif type == ".json" || type == ".js"
        @@dreams = JSON.load_file d
      elsif type == ".rb"
        @@dreams = eval File.read d
      else
        raise BadDreams, d
      end
    elsif d.kind_of?(Hash)
      @@dreams = d
    else
      raise BadDreams, d
    end
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

  
  def self.tryout(name, type=:cli, command=nil, &b)
    command ||= @@command if type == :cli
    to = Tryouts::Tryout.new(name, type, command)
    to.from_block b
    @@tryouts << to
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
  
end
