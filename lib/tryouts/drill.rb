

class Tryouts
  
  # = Drill
  # 
  # This class represents a drill. A drill is single test. 
  #
  class Drill
    
  require 'tryouts/drill/context'
  require 'tryouts/drill/response'
  require 'tryouts/drill/sergeant/cli'
  require 'tryouts/drill/sergeant/api'
  require 'tryouts/drill/sergeant/benchmark'
  require 'tryouts/drill/sergeant/rbenchmark'
  
  class NoSergeant < Tryouts::Exception; end
  class UnknownFormat < Tryouts::Exception; end
  
    # A symbol specifying the drill type. One of: :cli, :api
  attr_reader :dtype
    # The name of the drill. This should match the name used in the dreams file. 
  attr_reader :name
    # A Proc object which contains the drill logic. 
  attr_reader :drill
  
    # A Sergeant object which executes the drill
  attr_reader :sergeant
    # An Array of Dream objects (the expected output of the test)
  attr_reader :dreams
    # A Reality object (the actual output of the test)
  attr_reader :reality
  
  @@valid_dtypes = [:cli, :api, :benchmark]
  
  def initialize(name, dtype, *args, &drill)
    @name, @dtype, @drill, @skip = name, dtype, drill, false
    @dreams = []
    case @dtype 
    when :cli
      @sergeant = Tryouts::Drill::Sergeant::CLI.new *args
    when :api
      default_output = drill.nil? ? args.shift : nil
      @sergeant = Tryouts::Drill::Sergeant::API.new default_output
      @dreams << Tryouts::Drill::Dream.new(*args) unless args.empty?
    when :benchmark
      default_output, format, reps = *args 
      @sergeant = Tryouts::Drill::Sergeant::Benchmark.new reps || 1
      @dreams << Tryouts::Drill::Dream.new(Float, :class)
      unless default_output.nil?
        @dreams << Tryouts::Drill::Dream.new(default_output, format)
      end
    when :skip
      @skip = true
    else
      raise NoSergeant, "Weird drill sergeant: #{@dtype}"
    end
    @clr = :red
    # For CLI drills, a block takes precedence over inline args. 
    # A block will contain multiple shell commands (see Rye::Box#batch)
    drill_args = [] if dtype == :cli && drill.is_a?(Proc)
    @reality = Tryouts::Drill::Reality.new
  end
  
  def self.valid_dtype?(t); @@valid_dtypes.member?(t); end
  
  def skip?; @skip; end
  
  def run(context=nil)
    begin
      @reality = @sergeant.run @drill, context
      # Store the stash from the drill block
      @reality.stash = context.stash if context.respond_to? :stash
      # If the drill block returned true we assume success if there's no dream
      if @dreams.empty? && @reality.output == true
        @dreams << Tryouts::Drill::Dream.new
        @dreams.first.output = true
      end
    rescue => ex
      @reality.ecode, @reality.etype = -2, ex.class
      @reality.error, @reality.trace = ex.message, ex.backtrace
    end  
    self.success?
  end
  
  def flag
    if success? 
      "PASS".color(@clr).bright 
    else
      note = @dreams.empty? ? '[nodream]' : ''
      "FAIL #{note}".color(@clr).bright
    end
  end
    
  def info
    out = StringIO.new
    if Tryouts.verbose > 1
      if @dreams.empty?
        out.puts '%6s%s'.color(@clr) % ['', @reality.output.inspect]
      else
        @dreams.each do |dream|
          if dream != @reality
            out.puts '%6s%s'.color(:red) % ['', @reality.output.inspect]
          else
            out.puts '%6s%s'.color(:green) % ["", dream.test_to_string(@reality)]
          end
        end
      end
    elsif Tryouts.verbose > 0
      out.puts '%6s%s'.color(@clr) % ['', @reality.output.inspect]
    end
    out.rewind
    out.read
  end
  
  def report
    return if skip?
    out = StringIO.new
    
    @dreams.each do |dream|
      next if dream == reality #? :normal : :red 
      out.puts '%12s: %s'.color(@clr) % ["failed", dream.test_to_string(@reality)]
      out.puts '%12s: %s' % ["returned", @reality.comparison_value(dream).inspect]
      out.puts '%12s: %s' % ["expected", dream.comparison_value.inspect]
      out.puts
    end
    
    @reality.stash.each_pair do |n,v|
      out.puts '%14s: %s' % [n,v.inspect]
    end
    
    unless @reality.error.nil?
      out.puts '%14s: %s' % [@reality.etype, @reality.error.to_s.split($/).join($/ + ' '*16)]
    end
    unless @reality.trace.nil?
      trace = Tryouts.verbose > 1 ? @reality.trace : [@reality.trace.first]
      out.puts '%14s  %s' % ['', trace.join($/ + ' '*16)]
      out.puts
    end
    
    out.rewind
    out.read
  end
  
  def success?
    return false if @dreams.empty? && @reality.output != true
    begin
      @dreams.each { |d| return false unless d == @reality }
    rescue => ex
      puts ex.message, ex.backtrace if Tryouts.debug?
      return false
    end
    @clr = :green
    true
  end
  
  
  def add_dream(d); @dreams << d; end
  def add_dreams(*d); @dreams += d; end
  
  private 
    
end; end
