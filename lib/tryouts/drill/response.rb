
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response
    attr_accessor :output, :format, :rcode, :emsg, :backtrace
    def initialize(output=nil, format=nil, rcode=0)
      @output, @format, @rcode = output, format, (rcode || 0)
      @format ||= :string
      @output = [] if @output.nil?
      normalize!
    end
    
    def ==(other)
      return false if other.nil?
      @rcode == other.rcode &&
      @emsg == other.emsg &&
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
    # This method is called automatically any time a field is updated.
    def normalize!
      @rcode = @rcode.to_i if @rcode.is_a?(String)
      @format = @format.to_sym if @format.is_a?(String)
    end
    def compare_output(other)
      return true if @output == other.output
      
      p self
      exit
      if @format == :class
        if @output.is_a?(Class)
          klass, payload = @output, other.output
        elsif other.output.is_a?(Class)
          klass, payload = other.output, @output
        end
        return payload.is_a?(klass)
      end
      
      if @output.kind_of?(Array) && other.kind_of?(Array)
        return false unless @output.size == other.output.size
      
        if @output.first.is_a?(Regexp)
          expressions, strings = @output, other.output
        elsif other.output.first.is_a?(Regexp)
          expressions, strings = other.output, @output
        end
      
        if !expressions.nil? && !strings.nil?
          expressions.each_with_index do |regex, index|
            return false unless strings[index] =~ regex
          end
          return true
        end
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
      d
    end
    
    def from_block(definition)
      instance_eval &definition
      self.normalize!
      self
    end
    
    # Takes a String +val+ and splits the lines into an Array. Each line
    # has 
    def inline(val=nil)
      lines = (val.split($/) || [])
      lines.shift if lines.first.strip == ""
      lines.pop if lines.last.strip == ""
      lines
    end
  end

  # = Reality 
  #
  # Contains the actual response of a Drill
  #
  class Reality < Tryouts::Drill::Response; end

end