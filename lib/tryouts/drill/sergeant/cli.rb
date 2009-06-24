

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
          ret = @rbox.send *@rbox_args
        else
          ret = @rbox.instance_eval &runtime
        end
        response.ecode = ret.exit_code
        if ret.stdout.size == 1
          response.output = ret.stdout.first 
        else
          response.output = Array.new(ret.stdout)  # Cast the Rye::Rap object
        end
        response.error = ret.stderr unless ret.stderr.empty?
      rescue Rye::CommandNotFound => ex
        puts ex.message, ex.backtrace if Tryouts.debug? && Tryouts.verbose > 2
        response.etype = ex.class
        response.ecode = ex.exit_code
        response.error = "[#{@rbox.host}] Command not found: #{ex.message}"
        response.trace = ex.backtrace
      rescue Rye::CommandError => ex
        puts ex.message, ex.backtrace if Tryouts.debug? && Tryouts.verbose > 2
        response.etype = ex.class
        response.ecode = ex.exit_code
        response.output = ex.stdout
        response.error = ex.stderr.join $/
        response.trace = ex.backtrace
      end
      response
    end
    
  end
  
end; end; end