

class Tryouts::Drill
  # = Dream
  #
  # Contains the expected response of a Drill
  #
  class Dream < Tryouts::Drill::Response
    
      # A proc which is run just before the associated drill. 
      # The return value overrides <tt>@output</tt>. 
    attr_accessor :output_block
    
    # Populates <tt>@output</tt> with the return value of
    # <tt>output_block</tt> or <tt>&definition</tt> if provided. 
    def execute_output_block(&definition)
      definition ||= @output_block
      return if definition.nil?
      self.output = instance_eval &definition
    end
    
    # Takes a String +val+ and splits the lines into an Array.
    def inline(val=nil)
      lines = (val.split($/) || [])
      lines.shift if lines.first.strip == ""
      lines.pop if lines.last.strip == ""
      lines
    end
  
    def ==(reality)
      return @answer unless @answer.nil?
      @answer = Response.compare(self, reality)
    end
  
    def test_to_string(reality)
      return @test_string unless @test_string.nil?
      @test_string = Response.compare_string(self, reality)
    end
  
    def comparison_value
      return @ret unless @ret.nil?
      @ret = case @format
      when :gt, :gte, :lt, :lte, :ne
        op = {:gt=>'>',:gte=>'>=', :lt=>'<', :lte => '<=', :ne => '!='}.find { |i| i[0] == @format }
        @output
      when :proc
        true
      when :respond_to?, :is_a?, :kind_of?
        true
      when :grep
        @output
      else 
        @output
      end
    end
  end
end
