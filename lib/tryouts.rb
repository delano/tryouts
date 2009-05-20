
require 'rubygems'
require 'ostruct'
require 'rye'
require 'yaml'
begin; require 'json'; rescue LoadError; end   # json may not be installed


class Tryouts
  class BadDreams < RuntimeError; end
  
  require 'tryouts/tryout'
  require 'tryouts/drill'
  
  TRYOUT_MSG = '  Tryout "%s": '
  DRILL_MSG  = '     Drill "%s":'
  
    # An Array of Tryout objects
  @@tryouts = []
  
    # A Hash of dreams
  @@dreams = {}
  
  
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
  
  # Add a shell command to Rye::Cmd
  def self.command(name, path=nil)
    Rye::Cmd.module_eval do
      define_method(name) do |*args|
        cmd(path || name, *args)
      end
    end
  end

  #    tryout :name do
  #       ...
  #    end
  def self.tryout(name, type=nil, &b)
    to = Tryouts::Tryout.new(name, type)
    to.from_block b
    @@tryouts << to
  end
  
  # Ignore a tryout
  def self.xtryout(name, &b)
  end
  
  def self.run
    puts "Tryouts for #{self}"
    @@tryouts.each do |to|
      to.run
    end
  end
  
  def self.print_report
    
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
