
require 'benchmark'


class Tryouts; class Drill; module Sergeant

  # = RBenchmark
  #
  # This is an implementation of Better-Benchmark:
  # http://github.com/Pistos/better-benchmark/
  #
  # NOTE: It's a work in progress and currently not functioning
  #
  # See also: http://www.graphpad.com/articles/interpret/Analyzing_two_groups/wilcoxon_matched_pairs.htm
  #
  module RBenchmark
    
    VERSION = '0.7.0'

    class ComparisonPartial
      def initialize( block, options )
        @block1 = block
        @options = options
      end

      def with( &block2 )
        times1 = []
        times2 = []

        (1..@options[ :iterations ]).each do |iteration|
          if @options[ :verbose ]
            $stdout.print "."; $stdout.flush
          end

          times1 << ::Benchmark.realtime do
            @options[ :inner_iterations ].times do |i|
              @block1.call( iteration )
            end
          end
          times2 << ::Benchmark.realtime do
            @options[ :inner_iterations ].times do |i|
              block2.call( iteration )
            end
          end
        end

        r = RSRuby.instance
        wilcox_result = r.wilcox_test( times1, times2 )

        {
          :results1 => {
            :times => times1,
            :mean => r.mean( times1 ),
            :stddev => r.sd( times1 ),
          },
          :results2 => {
            :times => times2,
            :mean => r.mean( times2 ),
            :stddev => r.sd( times2 ),
          },
          :p => wilcox_result[ 'p.value' ],
          :W => wilcox_result[ 'statistic' ][ 'W' ],
          :significant => (
            wilcox_result[ 'p.value' ] < @options[ :required_significance ]
          ),
        }
      end
      alias to with
    end

    # Options:
    # :iterations
    # The number of times to execute the pair of blocks.
    # :inner_iterations
    # Used to increase the time taken per iteration.
    # :required_significance
    # Maximum allowed p value in order to declare the results statistically significant.
    # :verbose
    # Whether to print a dot for each iteration (as a sort of progress meter).
    #
    # To use better-benchmark properly, it is important to set :iterations and
    # :inner_iterations properly. There are a few things to bear in mind:
    #
    # (1) Do not set :iterations too high. It should normally be in the range
    # of 10-20, but can be lower. Over 25 should be considered too high.
    # (2) Execution time for one run of the blocks under test should not be too
    # small (or else random variance will muddle the results). Aim for at least
    # 1.0 seconds per iteration.
    # (3) Minimize the proportion of any warmup time (and cooldown time) of one
    # block run.
    #
    # In order to achieve these goals, you will need to tweak :inner_iterations
    # based on your situation. The exact number you should use will depend on
    # the strength of the hardware (CPU, RAM, disk), and the amount of work done
    # by the blocks. For code blocks that execute extremely rapidly, you may
    # need hundreds of thousands of :inner_iterations.
    def self.compare_realtime( options = {}, &block1 )
      require 'rsruby'
      
      options[ :iterations ] ||= 20
      options[ :inner_iterations ] ||= 1
      options[ :required_significance ] ||= 0.01

      if options[ :iterations ] > 30
        warn "The number of iterations is set to #{options[ :iterations ]}. " +
          "Using too many iterations may make the test results less reliable. " +
          "It is recommended to increase the number of :inner_iterations instead."
      end

      ComparisonPartial.new( block1, options )
    end

    def self.report_on( result )
      puts
      puts( "Set 1 mean: %.3f s" % [ result[ :results1 ][ :mean ] ] )
      puts( "Set 1 std dev: %.3f" % [ result[ :results1 ][ :stddev ] ] )
      puts( "Set 2 mean: %.3f s" % [ result[ :results2 ][ :mean ] ] )
      puts( "Set 2 std dev: %.3f" % [ result[ :results2 ][ :stddev ] ] )
      puts "p.value: #{result[ :p ]}"
      puts "W: #{result[ :W ]}"
      puts(
        "The difference (%+.1f%%) %s statistically significant." % [
          ( ( result[ :results2 ][ :mean ] - result[ :results1 ][ :mean ] ) / result[ :results1 ][ :mean ] ) * 100,
          result[ :significant ] ? 'IS' : 'IS NOT'
        ]
      )
    end
  end
  
end; end; end

