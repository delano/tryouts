



class Tryouts; class Drill; module Sergeant
  
  # = Benchmark
  # 
  # The sergeant responsible for running benchmarks
  #
  class Benchmark
    require 'benchmark'
    
    attr_reader :output
    
    FIELDS = [:utime, :stime, :cutime, :cstime, :total, :real].freeze
    
    # * +reps+ Number of times to execute drill (>= 0, <= 1000000). Default: 3
    #
    def initialize(reps=nil)
      @reps = (1..1000000).include?(reps) ? reps : 5
      @warmups = reps < 10 ? 1 : 10
      @stats = {}
    end
  
    def run(block, context, &inline)
      # A Proc object takes precedence over an inline block. 
      runtime = (block.nil? ? inline : block)
      response = Tryouts::Drill::Reality.new
      
      if runtime.nil?
        raise "We need a block to benchmark"
      else
        begin
          
          @warmups.times do
            tms = ::Benchmark.measure {
              context.instance_eval &runtime
            }
          end
          
          @stats[:rtotal] = Tryouts::Stats.new(:rtotal)
          @reps.times do
            tms = ::Benchmark.measure {
              context.instance_eval &runtime
            }
            process_tms(tms)
          end
          @stats[:rtotal].tick
          
          # We add the output after we run the block so that
          # that it'll remain nil if an exception was raised
          response.output = @stats
          
        rescue => e
          puts e.message, e.backtrace if Tryouts.verbose > 2
          response.etype = e.class
          response.error = e.message
          response.trace = e.backtrace
        end
      end
      response
    end
    
    def process_tms(tms)
      FIELDS.each do |f|
        @stats[f] ||= Tryouts::Stats.new(f)
        @stats[f].sample tms.send(f)
      end
    end
    
    def self.fields() FIELDS end
    
  end
end; end; end