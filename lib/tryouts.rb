require 'pathname'
begin
  require 'ruby-debug'
rescue LoadError, RuntimeError
end

module Tryouts

  class Suite
  end

  class Case
    def initialize(str)
      @str = str
    end

    def run
      tests
      #tests.map {|test| print (test.passed? ? '.' : 'F') }
      #statuses = tests.map {|test| print (test.passed? ? '.' : 'F'); test.passed? }
      #statuses.include?(false) ? 1 : 0

      0
    end

    def tests
      @tests ||= Tests.new(@str)
    end
  end

  class Tests < Array
    def initialize(str)
      self.replace extract_tests!(str)
    end

    private
    def extract_tests!(str)
      tests = []
      xflag = false
      test_lines = []

      str.each_line do |line|
        line = line.strip
        #if line =~ /^\s*#=>/
        if line =~ /#\s?=>/
          test_lines << line
          xflag = true
        elsif line.empty? && xflag
          tests << Test.new(test_lines.join("\n"))
          test_lines = [] #reset
          xflag = false
        else
          test_lines << line
        end
      end

      tests
    end
  end

  class Test

    attr_accessor :expected

    def initialize(str)
      @str = str
    end

    def to_s
      @str
    end

    class EvalContext

      class << self
        #attr_accessor :setup, :teardown
        def evaluate(str)
          @context = new
          #@context.instance_eval(setup)
          @context.instance_eval(str)
          #@context.instance_eval(teardown)
        end
      end

      def require(*args)
        # noop
      end
    end
  end
end

file = Pathname(caller.last.split(':').first)
line = caller.last.split(':').last.to_i
str  = file.read.split("\n")[(line)..-1].join("\n")
exit Tryouts::Case.new(str).run


#test_case = Tryouts::Case.new( Pathname($0).read )
#test_case.tests.each {|test| puts test }



__END__
require 'pathname'
require 'ruby-debug'

class TestContext
  class << self
    attr_accessor :setup, :teardown
  end
  def self.eval(str)
    @context ||= new
    #@context.instance_eval(setup)
    @context.instance_eval(str)
    #@context.instance_eval(teardown)
  end
  def require(*args)
    # noop
  end
end

file = Pathname(caller.last.split(':').first)

result, expected = nil, nil
file.read.each_line do |line|
  if line.match(/#=>/)
    next if line.match(/#\s*#=>/)
    expected = line.split('#=>').last.strip
    passed = (result == TestContext.eval(expected))
    print (passed ? '.' : 'F')
  elsif line.strip.empty?
    next
  elsif line.match(/^\s*#/)
    next
  else
    result = TestContext.eval(line)
  end
end

puts
exit

