require 'pathname'
require 'every'
require 'ruby-debug'

module Tryouts
  class Suite
  end
  class Case
    def tests

    end
  end
  class Test
    def initialize(code, expected)
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
test_case = Tryouts::Case.run(file.read)


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

