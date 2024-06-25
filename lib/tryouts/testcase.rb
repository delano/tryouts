# frozen_string_literal: true

class Tryouts
  class TestCase
    attr_reader :desc, :test, :exps, :path, :outlines, :test_result

    def initialize(d, t, e)
      @desc, @test, @exps, @path = d, t, e
      @outlines = []
    end

    def inspect
      [@desc.inspect, @test.inspect, @exps.inspect].join
    end

    def to_s
      [@desc.to_s, @test.to_s, @exps.to_s].join
    end

    def run
      Tryouts.debug format('%s:%d', @test.path, @test.first)
      Tryouts.debug inspect, $/
      $stdout = StringIO.new
      expectations = exps.collect do |exp, _idx|
        exp =~ /\A\#?\s*=>\s*(.+)\Z/
        ::Regexp.last_match(1) # this will be nil if the expectation is commented out
      end

      # Evaluate test block only if there are valid expectations
      unless expectations.compact.empty?  # TODO: fast-fail if no expectations
        test_value = Tryouts.eval @test.to_s, @test.path, @test.first
        @has_run = true
      end
      $stdout = STDOUT # restore stdout

      expectations.each_with_index do |exp, idx|
        if exp.nil?
          @outlines << '     [skipped]'
          @test_result = 0
        else
          # Evaluate expectation

          exp_value = Tryouts.eval(exp, @exps.path, @exps.first + idx)

          test_passed = test_value.eql?(exp_value)
          @test_result = test_passed ? 1 : -1
          @outlines << test_value.inspect
        end
      end
      Tryouts.debug # extra newline
      failed?
    end

    def run?
      @has_run.eql?(true)
    end

    def skipped?
      @test_result == 0
    end

    def passed?
      @test_result == 1
    end
    def failed?
      @test_result == -1
    end

    def color
      case @test_result
      when 1
        :green
      when 0
        :white
      else
        :red
      end
    end

    def adjective
      case @test_result
      when 1
        'PASSED'
      when 0
        'SKIPPED'
      else
        'FAILED'
      end
    end

  end
end
