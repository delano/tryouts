
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response
    attr_accessor :output, :format, :rcode, :emsg, :backtrace
    def initialize(output=nil, format=nil, rcode=0)
      @output, @format, @rcode = output, format, rcode
      @format ||= :string
      @output ||= []
      normalize!
    end
    
    def ==(other)
      self.rcode == other.rcode &&
      self.emsg == other.emsg &&
      compare_output(other)
    end
    def rcode(val=nil); @rcode = val unless val.nil?; normalize!; @rcode; end
    def output(val=nil); @output = val unless val.nil?; normalize!; @output; end
    def emsg(val=nil); @emsg = val unless val.nil?; normalize!; @emsg; end
    def format(val=nil); @format = val unless val.nil?; normalize!; @format; end
    
    def output=(val); @output = val; normalize!; @output; end
    def rcode=(val); @rcode = val; normalize!; @rcode; end
    def format=(val); @format = val; normalize!; @format; end
    def emsg=(val); @emsg = val; normalize!; @emsg; end
    
    # Enforce the following restrictions on the data fields:
    # * +rcode+ is an Integer
    # * +format+ is a Symbol
    # * +output+ is an Array with empty strings and nils removed. 
    # This method is called automatically any time a field is updated.
    def normalize!
      @rcode = @rcode.to_i if @rcode.is_a?(String)
      @format = @format.to_sym if @format.is_a?(String)
      @output = [@output] unless @output.is_a?(Array)
      return unless @output.is_a?(Array)
      @output = @output.compact.collect { |line| line.strip }.reject { |line| line == "" }
    end
    def compare_output(other)
      return true if self.output == other.output
      return false unless self.output.size == other.output.size
      
      if self.output.first.is_a?(Regexp)
        expressions = self.output 
        strings = other.output
      elsif other.output.first.is_a?(Regexp)
        expressions = other.output 
        strings = self.output
      end
      
      if defined?(expressions) && defined?(strings)
        # Returns true only when every result returns true
        return !(self.output.collect { |regex| r.success? }.member?(false))
        expressions.each_with_index do |regex, index|
          return false unless strings[index] =~ regex
        end
        return true
      end
      
      false
    end

  end


  # = Dream
  #
  # Contains the expected response of a Drill
  #
  class Dream < Tryouts::Drill::Response
    
    def self.from_block(definition)
      d = Tryouts::Drill::Dream.new
      d.from_block definition
      p d
      d
    end
    
    def from_block(definition)
      instance_eval &definition
      self.normalize!
      self
    end
    
    def inline(val=nil)
      lines = (val.split($/) || [])
    end
  end

  # = Reality 
  #
  # Contains the actual response of a Drill
  #
  class Reality < Tryouts::Drill::Response; end

end