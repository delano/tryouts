


class Tryouts; class Drill; module Sergeant
  
  # = API
  # 
  # The sergeant responsible for running Ruby code (API) drills.
  #
  class API
    
    attr_reader :output
    
    # +opts+ is a Hash with the following optional keys:
    #
    # * +:output+ specify a return value. This will be 
    # used if no block is specified for the drill.
    def initialize(output=nil)
      @output = output
    end
  
    def run(block, context, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      if runtime.nil?
        response.output = @output
      else
        begin
          response.output = context.instance_eval &runtime
        rescue => e
          puts e.message, e.backtrace if Tryouts.verbose > 2
          response.etype = e.class
          response.error = e.message
          response.trace = e.backtrace
        end
      end
      response
    end
    
  end
end; end; end