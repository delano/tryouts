

class Tryouts; class Drill; module Sergeant
  
  # = CLI
  # 
  # The sergeant responsible for running command-line interface drills.
  #
  class CLI
  
    attr_reader :rbox
    
      # An Array of arguments to be sent to +rbox.send(*rbox_args)+
    attr_accessor :rbox_args
    
    def initialize(*args)
      @rbox_args = args
      @rbox = Rye::Box.new
    end
  
    # NOTE: Context is ignored for the CLI Sergeant. 
    def run(block, context=nil, &inline)
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
        response.output = ret.stdout.size == 1 ? ret.stdout.first : Array.new(ret.stdout)  # Cast the Rye::Rap object
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
  
end; end; end