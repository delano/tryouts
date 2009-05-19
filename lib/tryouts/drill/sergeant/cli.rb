

module Tryouts::Drill::Sergeant
  class CLI
  
    attr_reader :rbox
  
    def initialize(*rbox_args)
      @rbox = Rye::Box.new(*rbox_args)
    end
  
    def run(block, &inline)
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      begin
        ret = @rbox.instance_eval &runtime
        response.rcode = ret.exit_code
        response.output = ret.stdout
        response.emsg = ret.stderr
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