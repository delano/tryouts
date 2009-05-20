

module Tryouts::Drill::Sergeant
  class CLI
  
    attr_reader :rbox
    
      # An Array of arguments to be sent to +rbox.send(*rbox_args)+
    attr_accessor :rbox_args
    
    def initialize(*rbox_args)
      @rbox_args = rbox_args
      @rbox = Rye::Box.new
    end
  
    def run(block, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      begin
        if runtime.nil?
          ret = @rbox.send *rbox_args
        else
          ret = @rbox.instance_eval &runtime
        end
        response.rcode = ret.exit_code
        response.output = Array.new(ret.stdout)  # Cast the Rye::Rap object
        response.emsg = ret.stderr unless ret.stderr.empty?
      rescue Rye::CommandNotFound => ex
        response.rcode = -2
        response.emsg = "[#{@rbox.host}] Command not found: #{ex.message}"
        response.backtrace = ex.backtrace
      rescue Rye::CommandError => ex
        response.rcode = ex.exit_code
        response.output = ex.stdout
        response.emsg = ex.stderr
      end
      response
    end
    
  end
end