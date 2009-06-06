
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response
    attr_accessor :output, :format, :rcode, :emsg, :backtrace
    def initialize(output=nil, format=nil, rcode=0)
      @output, @format, @rcode = output, format, (rcode || 0)
      @output = nil if @output.nil?
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
      #
      # The dream is always on the left (Does your dream match reality?)
      # This check is important so we can support both:
      # @dream == @reality
      #  AND
      # @reality == @dream
      #
      if self.is_a? Tryouts::Drill::Dream
        dream, reality = self, other
      elsif self.is_a? Tryouts::Drill::Reality
        dream, reality = other, self
      else
        # If self isn't a Dream or a Reality, then we have a problem
        return false
      end
      
      # The matching statement will be the return value. 
      if dream.format.nil?
        dream.output == reality.output
      elsif reality.respond_to? dream.format
        reality.output.send(dream.format) == dream.output 
      else
        false
      end
      
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