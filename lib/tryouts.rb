#require 'pathname'
#p Pathname(caller.last.split(':').first)

class Tryouts
  
  class Expectation 
    attr_accessor :value, :expected_values, :desc
    attr_reader :results, :tests
    def initialize(value, *expected_values)
      @value, @expected_values = value, expected_values
      @tests = []
    end
    def run_all
      @results = expected_values.collect do |expectation|
        str = '%s == %s' % [@value, expectation]
        ret = eval(@value) == eval(expectation)
        @tests << [str, ret]
        ret
      end
    end
    def success?
      @results.uniq == [true]
    end
  end
  
  class << self
  
    def preparse(path)
      lines = File.readlines(path)
      lines.size.times do |idx|
        line = lines[idx]
        if expectation? line
          value = find_value lines, idx
          next if value.nil?
          expected_values = find_expected_values lines, idx
          desc = find_description lines, idx
          exp = Expectation.new value, *expected_values
          exp.desc = desc
          exp.run_all
          puts exp.desc
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
    
    def find_value lines, start
      value = nil
      offset = 1
      until interesting?(lines[start-offset])
        break if expectation?(lines[start-offset]) || (start-offset) < 0
        offset += 1 
      end
      value = lines[start-offset].chomp if interesting?(lines[start-offset])
      value
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

