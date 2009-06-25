



class Tryouts; class Drill; module Sergeant
  
  # = Benchmark
  # 
  # The sergeant responsible for running benchmarks
  #
  class Benchmark
    require 'benchmark'
    
    attr_reader :output
    
    # * +reps+ Number of times to execute the block
    #
    def initialize(reps=1)
      @reps = reps
      p [:reps, reps]
    end
  
    def run(block, context, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      if runtime.nil?
        raise "We need a block to benchmark"
      else
        begin
          
          response.output = ::Benchmark.realtime &runtime
          
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