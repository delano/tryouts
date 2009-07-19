
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
      
      # Refactor like:
      # http://github.com/why/hpricot/blob/master/lib/hpricot/elements.rb#L475
      
      begin
        case dream.format
        when :exception
          reality.etype == dream.output
        when :match
          reality.output.respond_to?(:match) &&
          !reality.output.match(dream.output).nil?
        when :proc
          dream.output.is_a?(Proc) &&
          reality.comparison_value(dream) == dream.comparison_value
        when :mean, :sdev
          reality.comparison_value(dream) <= dream.comparison_value
        when :gt
          reality.output > dream.output
        when :gte
          reality.output >= dream.output
        when :lt
          reality.output < dream.output
        when :lte
          reality.output <= dream.output
        when :ne
          reality.output != dream.output
        when :respond_to?, :kind_of?, :is_a?
          reality.output.send(dream.format, dream.output)
        when :grep
          !reality.output.grep(dream.output).empty?
        else 
        
          if dream.format.nil?
            reality.output == dream.output
          elsif reality.output.respond_to?(dream.format)
            reality.comparison_value(dream)  == dream.output
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
        when :proc
          test = dream.output
          test.arity > 0 ? "Proc.call(reality) == true" : "Proc.call == true"
        when :exception
          "#{reality.etype} == #{dream.output}"
        when :mean, :sdev
          "#{reality.comparison_value(dream)} <= #{dream.output}"
        when :match
          "#{reality.output.inspect}.match(#{dream.output.inspect})"
        when :gt, :gte, :lt, :lte, :ne
          op = {:gt=>'>',:gte=>'>=', :lt=>'<', :lte => '<=', :ne => '!='}.find { |i| i[0] == dream.format }
          "#{reality.output.inspect} #{op[1]} #{dream.output.inspect}"
        when :respond_to?, :kind_of?, :is_a?
          "#{reality.output.class}.#{dream.format} #{dream.output.inspect}"
        when :grep
          "!#{reality.output}.grep(#{dream.output.inspect}).empty?"
        else 
        
          if dream.format.nil?
            "#{reality.output.inspect} == #{dream.output.inspect}"
          elsif reality.output.respond_to?(dream.format)
            "#{reality.output.inspect}.#{dream.format} == #{dream.output.inspect}"
          else
            "Unknown method #{dream.format.inspect} for #{reality.output.class} "
          end
        
        end
      rescue => ex
        puts ex.message, ex.backtrace if Tryouts.debug? 
        reality.error, reality.trace, reality.etype = ex.message, ex.backtrace, ex.class
        return ""
      end
    
    end
    
  end


end