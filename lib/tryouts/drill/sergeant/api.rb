


class Tryouts; class Drill; module Sergeant
  
  # = API
  # 
  # The sergeant responsible for running Ruby code (API) drills.
  #
  class API
    
    # +return_value+ specify a return value. This will be 
    # used if no block is specified for the drill.
    def initialize(return_value=nil)
      @return_value = return_value
    end
  
    def run(block, context, &inline)
      
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      if runtime.nil?
        response.output = @return_value
      else
        begin
          unless runtime.nil?
            ret = context.instance_eval &runtime
            response.output, response.rcode = ret, 0
          end
        rescue => ex
          response.rcode = 1
          response.output = ret
          response.emsg = ex.message
          response.backtrace = ex.backtrace
        end
      end
      response
    end
    
  end
end; end; end