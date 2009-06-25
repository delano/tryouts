



class Tryouts; class Drill; module Sergeant
  
  # = API
  # 
  # The sergeant responsible for running Ruby code (API) drills.
  #
  class Ben
    require 'benchmark'
    
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
        raise "We need a block to benchmark"
      else
        begin
          
          Benchmark.bmbm &runtime
          
          response.output = true
          
        rescue => e
          puts e.message, e.backtrace if Tryouts.verbose > 2
          response.output = false
          response.etype = e.class
          response.error = e.message
          response.trace = e.backtrace
        end
      end
      response
    end
    
  end
end; end; end