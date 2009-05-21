
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response
    attr_writer :rcode, :output, :format, :emsg, :backtrace
    def initialize
      @rcode = 0
      @format = :string
      @output = []
    end
    
    def ==(other)
      self.rcode == other.rcode &&
      self.output == other.output &&
      self.emsg == other.emsg
    end
    def rcode(val=nil); @rcode = val unless val.nil?; @rcode; end
    def output(val=nil); @output = val unless val.nil?; @output; end
    def emsg(val=nil); @emsg = val unless val.nil?; @emsg; end
    def format(val=nil); @format = val unless val.nil?; @format; end
    
    def normalize!
      @rcode = @rcode.to_i if @rcode.is_a?(String)
      @format = @format.to_sym if @format.is_a?(String)
      return unless @output.is_a?(Array)
      @output = @output.collect { |line| line.strip }.reject { |line| line == "" }
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