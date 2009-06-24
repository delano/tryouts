
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response
    attr_accessor :output, :format
    def initialize(output=nil, format=nil)
      @output, @format = output, format
    end
    
    def format(val=nil); @format = val.to_sym unless val.nil?; @format; end
    def format=(val); @format = val.to_sym; @format; end
    
    def Response.compare(dream, reality)
      return false if reality.nil?
      
      ## I don't think this check is necessary or useful
      ##return false unless reality.error.nil? && reality.trace.nil?
      return true if reality.output == true and dream.nil?

      case dream.format
      when :class
        reality.output.class == dream.output
      when :exception
        reality.etype == dream.output
      when :regex
        !reality.output.match(dream.output).nil?
      else 
        reality.output == dream.output
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
      self
    end
    
    # Takes a String +val+ and splits the lines into an Array.
    def inline(val=nil)
      lines = (val.split($/) || [])
      lines.shift if lines.first.strip == ""
      lines.pop if lines.last.strip == ""
      lines
    end
    
    def ==(reality)
      Response.compare(self, reality)
    end
  end

  # = Reality 
  #
  # Contains the actual response of a Drill
  #
  class Reality < Tryouts::Drill::Response
      # An ordered hash taken from the DrillContext that created this Reality. 
    attr_accessor :stash
    attr_accessor :error
    attr_accessor :trace
    attr_accessor :ecode
    attr_accessor :etype
    def initialize
      @stash = Tryouts::HASH_TYPE.new
    end
    
    def ==(dream)
      Response.compare(dream, self)
    end
  end

end