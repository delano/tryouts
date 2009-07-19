class Tryouts::Drill
  
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
      # For :cli drills only. Contains the shell command string. 
    attr_accessor :command
    def initialize
      @stash = Tryouts::HASH_TYPE.new
    end
    
    def ==(dream)
      Response.compare(dream, self)
    end
    
    def comparison_value(dream)
      case dream.format
      when :proc
        test = dream.output
        (test.arity > 0 ? test.call(@output) : test.call)
      when :exception
        @etype
      when :respond_to?, :is_a?, :kind_of?, :grep
        @output.send(dream.format, dream.output)
      when nil
        @output
      else 
        return nil if @output.nil? 
        
        if !dream.format.is_a?(Symbol)
          "This dream format is not a Symbol: #{dream.format}"
        elsif @output.respond_to?(dream.format)
          @output.send(dream.format)
        else
          @output
        end
      end
    end
  end

end