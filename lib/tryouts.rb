#require 'pathname'
#p Pathname(caller.last.split(':').first)
require 'ostruct'

class Tryouts
  @debug = false
  class TestCase
    class Container
      def metaclass
        class << self; end
      end
    end
    attr_reader :desc, :test, :exps
    def initialize(d,t,e)
      @desc, @test, @exps, @path = d,t,e
      @container = Container.new.metaclass
    end
    def inspect
      [@desc.inspect, @test.inspect, @exps.inspect].join
    end
    def to_s
      [@desc.to_s, @test.to_s, @exps.to_s].join
    end
    def test
      create_proc @test.join("#{$/}  "), @test.path, @test.first
    end
    def expectations
      list = []
      @exps.each_with_index do |exp,idx| 
        exp =~ /\#+\s*=>\s*(.+)$/
        list << create_proc($1, @exps.path, @exps.first+idx)
      end
      list
    end
    def run
      Tryouts.debug '-'*40
      Tryouts.debug inspect, $/
      test_value = @container.class.module_eval &test
      results = expectations.collect { |exp| 
        ret = test_value == @container.class.module_eval(&exp) 
        color = ret ? :green : :red
        Tryouts.print Console.color(color, '.')
        ret
      }
      Tryouts.debug
      results.uniq == [true]
    end
    private
    def create_proc str, path, line
      eval("Proc.new {\n  #{str}\n}", binding, path, line)
    end
  end
  class Section < Array
    attr_accessor :path, :first, :last
    def initialize path, start=0
      @path = path
      @first, @last = start, start
    end
    def range
      @first..@last
    end
    def inspect
      range.to_a.zip(self).collect do |line|
        "%-4d %s\n" % line
      end.join
    end
    def to_s
      self.join($/) << $/
    end
  end
  
  @cases = []
  class << self
    attr_accessor :debug
    attr_reader :cases
    
    def try path
      cases = parse path
      passed = cases.select { |t| 
        t.run
      }
      msg $/, "Passed #{passed.size} of #{cases.size} tests"
      passed.size == cases.size
    end
    
    def parse path
      debug "Loading #{path}"
      lines = File.readlines path
      skip_ahead = 0
      cases = []
      lines.size.times do |idx|
        skip_ahead -= 1 and next if skip_ahead > 0
        line = lines[idx].chomp
        #debug('%-4d %s' % [idx, line])
        if expectation? line
          offset = 0
          exps = Section.new(path, idx+1)
          exps << line.chomp
          while (idx+offset < lines.size)
            offset += 1
            this_line = lines[idx+offset]
            break if ignore?(this_line)
            if expectation?(this_line)
              exps << this_line
              skip_ahead += 1
            end
            exps.last += 1
          end
          
          offset = 0
          buffer, desc = Section.new(path), Section.new(path)
          test = Section.new(path, idx)  # test start the line before the exp. 
          while (idx-offset >= 0)
            offset += 1
            this_line = lines[idx-offset].chomp
            test.unshift this_line if ignore?(this_line)
            buffer.unshift this_line if comment?(this_line)
            if test?(this_line)
              test.unshift(*buffer) && buffer.clear
              test.unshift this_line
            end
            if test_begin?(this_line) || expectation?(this_line) || idx-offset == 0
              test.first = idx-offset+buffer.size+1
              desc.unshift *buffer
              desc.last = test.first-1
              desc.first = desc.last-desc.size+1
              break 
            end
          end
          
          cases << TestCase.new(desc, test, exps)
        end
      end
      cases
    end
    
    def print str
      STDOUT.print str
      STDOUT.flush
    end
    
    def msg *msg
      STDOUT.puts *msg
    end
    
    def debug *msg
      STDERR.puts *msg if @debug
    end
    
    private
    
    def expectation? str
      !ignore?(str) && str.strip.match(/^\#\s*=>/)
    end
    
    def comment? str
      !str.strip.match(/^\#+/).nil? && !expectation?(str)
    end
    
    def test? str
      !ignore?(str) && !expectation?(str) && !comment?(str)
    end
    
    def ignore? str
      str.to_s.strip.chomp.empty?
    end
    
    def test_begin? str
      !str.strip.match(/^\#+\s*TEST/i).nil?
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

