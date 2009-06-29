

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
  
  @@valid_dtypes = [:api, :benchmark]
  
  # * +name+ The display name of this drill
  # * +dtype+ A Symbol representing the drill type. One of: :api, :benchmark
  # * +args+ These are dependent on the drill type. See the Sergeant classes
  # * +&drill+ The body of the drill. The return value of this block 
  #   is compared to the exepected output of the dreams. 
  #
  # The DSL syntax:
  # * dream OUTPUT
  # * dream FORMAT, OUTPUT
  # * dream FORMAT, OUTPUT, REPS      (benchmark only)
  #
  def initialize(name, dtype, *args, &drill)
    @name, @dtype, @drill, @skip = name, dtype, drill, false
    @dreams = []
    case @dtype 
    when :cli
      @sergeant = Tryouts::Drill::Sergeant::CLI.new *args
    when :api
      default_output = drill.nil? ? args.shift : nil
      @sergeant = Tryouts::Drill::Sergeant::API.new default_output
      unless args.empty?
        if args.size == 1
          dream_output, format = args.first, nil
        else
          dream_output, format = args[1], args[0]
        end
        @dreams << Tryouts::Drill::Dream.new(dream_output, format)
      end
    when :benchmark
      if args.size == 1
        reps = args.first
      else
        dream_output, format, reps = args[1], args[0], args[2]
      end
      @sergeant = Tryouts::Drill::Sergeant::Benchmark.new reps
      @dreams << Tryouts::Drill::Dream.new(Tryouts::Stats, :class)
      unless dream_output.nil?
        @dreams << Tryouts::Drill::Dream.new(dream_output, format)
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
  
  def self.valid_dtypes; @@valid_dtypes; end
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
    if skip?
      "SKIP"
    elsif success? 
      "PASS".color(@clr).bright 
    else
      note = @dreams.empty? ? '[nodream]' : ''
      "FAIL #{note}".color(@clr).bright
    end
  end
    
  def info
    out = StringIO.new
    if Tryouts.verbose > 0
      if @dtype == :benchmark
        unless @reality.output.nil?
          mean, sdev, sum = @reality.output.mean, @reality.output.sdev, @reality.output.sum
          out.puts '%6s%.4f (sdev:%.4f sum:%.4f)'.color(@clr) % ['', mean, sdev, sum]
        end
      else
        out.puts '%6s%s'.color(@clr) % ['', @reality.output.inspect]
      end
      unless @reality.stash.empty?
        @reality.stash.each_pair do |n,v|
          out.puts '%18s: %s'.color(@clr) % [n,v.inspect]
        end
      end
    end
    if Tryouts.verbose > 1

      @dreams.each do |dream|
        if dream != @reality
          out.puts '%6s%s'.color(:red) % ['', dream.test_to_string(@reality)]
        else
          out.puts '%6s%s'.color(:green) % ["", dream.test_to_string(@reality)]
        end
      end  
      out.puts
    
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
      out.puts '%12s: %s' % ["drill", @reality.comparison_value(dream).inspect]
      out.puts '%12s: %s' % ["dream", dream.comparison_value.inspect]
      out.puts
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
  
  def has_error?
    !@reality.error.nil?
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
