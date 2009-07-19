

class Tryouts::Drill
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
      self.output = instance_eval &definition
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
