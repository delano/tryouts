#require 'pathname'
#p Pathname(caller.last.split(':').first)

class Tryouts
  @debug = false
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
    attr_accessor :debug
    def preparse(lines)
      lines.each do |line|
        next if ignore?(line)
        eval(line) if line.match(/require/)
        break if expectation?(line)
      end
    end
    def parse(path)
      container = Container.new
      lines = File.readlines(path)
      preparse lines
      tests = []
      lines.size.times do |idx|
        line = lines[idx]
        puts '%d %s' % [idx line] if @debug
        if expectation? line
          body = find_body lines, idx
          next if body.nil? 
          expected_values = find_expected_values lines, idx
          desc = find_description lines, idx
          exp = Expectation.new body, *expected_values
          exp.desc = desc
          exp.container = container
          tests << exp
        end
      end
      results = tests.collect do |exp|
        msg = [exp.desc, exp.body, exp.expected_values]
        exp.run_all
        color = exp.success? ? :green : :red
        print Console.color(color, '.')
        msg.join($/)
        exp.success?
      end
      puts $/, "Passed #{results.select { |obj| obj == true}.size} of #{tests.size}"
    end
    

    private
    
    def find_expected_values lines, start
      expected = [lines[start]]
      offset = 1
      while (start+offset) < lines.size && expectation?(lines[start+offset])
        expected << lines[start+offset]
        offset += 1 
      end
      expected.collect { |v| v.match(/^\#\s*=>\s*(.+)/); $1.chomp }
    end
    
    def find_body lines, start
      body = []
      offset = 1
      while interesting?(lines[start-offset]) || !expectation?(lines[start-offset])
        body.unshift lines[start-offset].chomp
        offset += 1 
        break if (start-offset) < 0
      end
      body.join $/
    end
    
    def find_description lines, start
      desc = []
      offset = 1
      offset += 1 until comment?(lines[start-offset]) || (start-offset) < 0
      if comment?(lines[start-offset])
        while comment?(lines[start-offset])
          desc << lines[start-offset].chomp
          offset +=1 
        end
      end
      desc.join $/
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
  
  module Console
    # ANSI escape sequence numbers for text attributes
    ATTRIBUTES = {
      :normal     => 0,
      :bright     => 1,
      :dim        => 2,
      :underline  => 4,
      :blink      => 5,
      :reverse    => 7,
      :hidden     => 8,
      :default    => 0,
    }.freeze unless defined? ATTRIBUTES

    # ANSI escape sequence numbers for text colours
    COLOURS = {
      :black   => 30,
      :red     => 31,
      :green   => 32,
      :yellow  => 33,
      :blue    => 34,
      :magenta => 35,
      :cyan    => 36,
      :white   => 37,
      :default => 39,
      :random  => 30 + rand(10).to_i
    }.freeze unless defined? COLOURS

    # ANSI escape sequence numbers for background colours
    BGCOLOURS = {
      :black   => 40,
      :red     => 41,
      :green   => 42,
      :yellow  => 43,
      :blue    => 44,
      :magenta => 45,
      :cyan    => 46,
      :white   => 47,
      :default => 49,
      :random  => 40 + rand(10).to_i
    }.freeze unless defined? BGCOLOURS
    
    def self.color(col, str)
      '%s%s%s' % [style(col), str, default_style]
    end
    def self.style(col, bgcol=nil, att=nil)
      valdor = []
      valdor << COLOURS[col] if COLOURS.has_key?(col)
      valdor << BGCOLOURS[bgcol] if BGCOLOURS.has_key?(bgcol)
      valdor << ATTRIBUTES[att] if ATTRIBUTES.has_key?(att)
      "\e[#{valdor.join(";")}m"   # => \e[8;34;42m  
    end
    def self.default_style
      style(:default, :default, :default)
    end
  end
end

