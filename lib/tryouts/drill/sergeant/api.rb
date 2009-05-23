


module Tryouts::Drill::Sergeant
  class API
    
    def initialize(*args)
    end
  
    def run(block, context, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      
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
      response
    end
    
  end
end