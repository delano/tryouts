



class Tryouts; class Drill; module Sergeant
  
  # = Benchmark
  # 
  # The sergeant responsible for running benchmarks
  #
  class Benchmark
    require 'benchmark'
    
    attr_reader :output
    
    # * +reps+ Number of times to execute drill (>= 0, <= 30). Default: 3
    #
    def initialize(reps=nil)
      @reps = (1..30).include?(reps) ? reps : 5
      @stats = Tryouts::Stats.new
    end
  
    def run(block, context, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      if runtime.nil?
        raise "We need a block to benchmark"
      else
        begin
          
          @reps.times do
            run = ::Benchmark.realtime &runtime
            @stats.sample run
          end
          
          response.output = @stats
          
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