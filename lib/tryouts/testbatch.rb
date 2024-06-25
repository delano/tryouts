# frozen_string_literal: true
#
class Tryouts
  class TestBatch < Array
    class Container
      def metaclass
        class << self; end
      end
    end
    attr_reader :path, :failed, :lines

    def initialize(p, l)
      @path = p
      @lines = l
      @container = Container.new.metaclass
      @run = false
    end

    def run(before_test, &after_test)
      return if empty?

      setup
      ret = self.select do |tc|
        before_test.call(tc) unless before_test.nil?
        ret = !tc.run
        after_test.call(tc)
        ret # select failed tests
      end
      @failed = ret.size
      @run = true
      clean
      !failed?
    rescue StandardError => e
      @failed = 1
      $stderr.puts e.message, e.backtrace.join($/), $/
    end

    def failed?
      !@failed.nil? && @failed > 0
    end

    def setup
      return if empty?

      start = first.desc.nil? ? first.test.first : first.desc.first - 1
      Tryouts.eval lines[0..start - 1].join, path, 0 if start > 0
    end

    def clean
      return if empty?

      last_line = last.exps.last + 1
      return unless last_line < lines.size

      Tryouts.eval lines[last_line..-1].join, path, last_line
    end

    def run?
      @run
    end
  end
end
