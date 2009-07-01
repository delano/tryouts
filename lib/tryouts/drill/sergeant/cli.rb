

class Tryouts; class Drill; module Sergeant
  
  # = CLI
  # 
  # The sergeant responsible for running command-line interface drills.
  #
  class CLI
    
    attr_accessor :rbox
    
      # An Array of arguments to be sent to <tt>rbox.send(@command, *rbox_args)</tt>
    attr_accessor :rbox_args
    
      # The command name to execute <tt>rbox.send(@command, *rbox_args)</tt>
    attr_accessor :command
    
    def initialize(*args)
      require 'rye'
      @command = args.shift
      @rbox_args = args
      @rbox = Rye::Box.new
    end
    
    # NOTE: Context is ignored for the CLI Sergeant. 
    def run(block, context=nil, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      
      if @command.nil?
        response.command = '[block]'
      else
        response.command = '$ ' << @rbox.preview_command(@command, *@rbox_args)
      end
      
      begin
        if runtime.nil?
          ret = @rbox.send @command, *@rbox_args
        else
          ret = @rbox.instance_eval &runtime
        end
        response.output = ret.stdout
        response.ecode = ret.exit_code
        response.error = ret.stderr unless ret.stderr.empty?
      rescue Rye::CommandNotFound => ex
        puts ex.message, ex.backtrace if Tryouts.verbose > 2
        response.etype = ex.class
        response.ecode = ex.exit_code
        response.error = "[#{@rbox.host}] Command not found: #{ex.message}"
        response.trace = ex.backtrace
      rescue Rye::CommandError => ex
        puts ex.message, ex.backtrace if Tryouts.verbose > 2
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