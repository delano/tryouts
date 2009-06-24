
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
      
      begin
        case dream.format
        when :exception
          reality.etype == dream.output
        when :match
          reality.output.respond_to?(:match) &&
          !reality.output.match(dream.output).nil?
        when :gt
          reality.output > dream.output
        when :gte
          reality.output >= dream.output
        when :lt
          reality.output < dream.output
        when :lte
          reality.output <= dream.output
        when :respond_to?
          reality.output.respond_to? dream.output 
        when :kind_of?
          reality.output.kind_of? dream.output
        when :is_a?
          reality.output.is_a? dream.output
        else 
        
          if dream.format.nil?
            reality.output == dream.output
          elsif reality.output.respond_to?(dream.format)
            reality.output.send(dream.format) == dream.output
          else 
            false
          end
        
        end
      rescue => ex
        puts ex.message, ex.backtrace if Tryouts.debug? 
        reality.error, reality.trace, reality.etype = ex.message, ex.backtrace, ex.class
        return false
      end
    end
    
    def Response.compare_string(dream, reality)
      return "[noreality]" if reality.nil?
      
      if reality.output == true and dream.nil?
        return "#{reality.output.inspect} == true" 
      end
      
      begin
        case dream.format
        when :exception
          "#{reality.etype} == #{dream.output}"
        when :match
          "#{reality.output.inspect}.match(#{dream.output.inspect})"
        when :gt, :gte, :lt, :lte
          op = {:gt=>'>',:gte=>'>=', :lt=>'<', :lte => '<='}.find { |i| i[0] == dream.format }
          "#{reality.output.inspect} #{op[1]} #{dream.output.inspect}"
        when :respond_to?
          "#{reality.output.inspect}.respond_to? #{dream.output.inspect}"
        when :kind_of?
          "#{reality.output.inspect}.kind_of? #{dream.output.inspect}"
        when :is_a?
          "#{reality.output.inspect}.is_a? #{dream.output.inspect}"
        else 
        
          if dream.format.nil?
            "#{reality.output.inspect} == #{dream.output.inspect}"
          elsif reality.output.respond_to?(dream.format)
            "#{reality.output.inspect}.#{dream.format} == #{dream.output.inspect}"
          else
            "#{reality.output.inspect}.respond_to?(#{dream.format.inspect}) == false"
          end
        
        end
      rescue => ex
        puts ex.message, ex.backtrace if Tryouts.debug? 
        reality.error, reality.trace, reality.etype = ex.message, ex.backtrace, ex.class
        return ""
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
    
    def test_to_string(reality)
      Response.compare_string(self, reality)
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