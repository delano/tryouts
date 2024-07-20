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

    def initialize(path, lines)
      @path = path
      @lines = lines
      @container = Container.new.metaclass
      @run = false
      #super
    end

    def run(before_test, &after_test)
      return if empty?
      testcase_score = nil

      setup
      failed_tests = self.select do |tc|
        before_test.call(tc) unless before_test.nil?
        begin
          testcase_score = tc.run  # returns -1 for failed, 0 for skipped, 1 for passed
        rescue StandardError => e
          testcase_score = -1
          warn Console.color(:red, "Error in test: #{tc.inspect}")
          warn Console.color(:red, e.message)
          warn e.backtrace.join($/), $/
        end
        after_test.call(tc) # runs the tallying code
        testcase_score.negative? # select failed tests
      end

      warn Console.color(:red, "Failed tests: #{failed_tests.size}") if Tryouts.debug?
      @failed = failed_tests.size
      @run = true
      clean
      !failed?

    rescue StandardError => e
      @failed = 1 # so that failed? returns true
      warn e.message, e.backtrace.join($/), $/
    end

    def failed?
      !@failed.nil? && @failed.positive?
    end

    def setup
      return if empty?

      start = first.desc.nil? ? first.test.first : first.desc.first - 1
      Tryouts.eval lines[0..start - 1].join, path, 0 if start.positive?
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
