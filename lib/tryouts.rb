#require 'pathname'
#p Pathname(caller.last.split(':').first)

class Tryouts
  class Container; end
  class Expectation 
    attr_accessor :body, :expected_values, :desc, :container
    attr_reader :results, :tests
    def initialize(body, *expected_values)
      @body, @expected_values = body, expected_values
      @expected_values.collect! { |exv| eval(exv) }
      @tests = []
    end
    def run_all
      @results = expected_values.collect do |expectation|
        ret = eval(body)
        @tests << [ret, expectation]
        ret == expectation
      end
    end
    def success?
      !@results.nil?  && @results.uniq == [true]
    end
  end
  
  class << self
  
    def preparse(path)
      container = Container.new
      lines = File.readlines(path)
      lines.size.times do |idx|
        line = lines[idx]
        if expectation? line
          body = find_body lines, idx
          next if body.nil? 
          expected_values = find_expected_values lines, idx
          desc = find_description lines, idx
          exp = Expectation.new body, *expected_values
          exp.desc = desc
          exp.container = container
          puts exp.desc
          puts exp.body
          p exp.expected_values
          
          exp.run_all
          puts exp.success? ? true : exp.tests
          puts
        end
      end
    end
    

    private
    
    def find_expected_values lines, start
      expected = [lines[start]]
      offset = 1
      while expectation?(lines[start+offset])
        expected << lines[start+offset]
        offset += 1 
        break (start+offset) > lines.size
      end
      expected.collect { |v| v.match(/^\#\s*=>\s*(.+)/); $1.chomp }
    end
    
    def find_body lines, start
      body = []
      offset = 1
      while interesting?(lines[start-offset])
        break if expectation?(lines[start-offset]) || (start-offset) < 0
        body.unshift lines[start-offset].chomp
        offset += 1 
      end
      body.join $/
    end
    
    def find_description lines, start
      desc = []
      offset = 1
      offset += 1 until comment?(lines[start-offset]) || (start-offset) < 0
      if comment?(lines[start-offset])
        while comment?(lines[start-offset])
          desc << lines[start-offset]
          offset +=1 
        end
      end
      desc
    end
    
    def expectation? str
      !ignore?(str) && str.strip.match(/^\#\s*=>/)
    end
    
    def comment? str
      !str.strip.match(/^\#/).nil?
    end
    
    def interesting? str
      !ignore?(str) && !expectation?(str) && !comment?(str)
    end
    
    def ignore? str
      str.strip.chomp.empty? || str.strip.match(/^\#\s*\w/)
    end
    
  end
  
end

