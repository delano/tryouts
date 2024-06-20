# frozen_string_literal: true

class Tryouts
  class TestCase
    attr_reader :desc, :test, :exps, :failed, :passed, :skipped

    def initialize(d, t, e)
      @desc, @test, @exps, @path = d, t, e
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
      expectations = exps.collect do |exp, _idx|
        exp =~ /\A\#?\s*=>\s*(.+)\Z/
        ::Regexp.last_match(1) # this will be nil if the expectation is commented out
      end

      # Evaluate test block only if there are valid expectations
      unless expectations.compact.empty?
        test_value = Tryouts.eval @test.to_s, @test.path, @test.first
        @has_run = true
      end

      @passed = []
      @failed = []
      @skipped = []
      expectations.each_with_index do |exp, idx|
        if exp.nil?
          @skipped << '     [skipped]'
        else
          exp_value = Tryouts.eval(exp, @exps.path, @exps.first + idx)
          if test_value == exp_value
            @passed << format('     ==  %s', test_value.inspect)
          else
            @failed << format('     !=  %s', test_value.inspect)
          end
        end
      end
      Tryouts.debug
      @failed.empty?
    end

    def skipped?
      !@skipped.nil? && !@skipped.empty?
    end

    def run?
      @has_run == true
    end

    def failed?
      !@failed.nil? && !@failed.empty?
    end

    private

    def create_proc(str, path, line)
      eval("Proc.new {\n  #{str}\n}", binding, __FILE__, __LINE__)
    end
  end
end
