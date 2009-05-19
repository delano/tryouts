
require 'rubygems'
require 'ostruct'
require 'rye'

class Tryouts
  require 'tryouts/tryout'
  require 'tryouts/drill'
  
    # An Array of Tryout objects
  @@tryouts = []
  
  def self.handle_known_exceptions
    
  end
  
  
  ## ----------------------------  EXTERNAL DSL  -----
  
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
