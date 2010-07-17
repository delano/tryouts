#require 'pathname'
#p Pathname(caller.last.split(':').first)
require 'ostruct'

class Tryouts
  @debug = false
  class TestCase
    attr_reader :desc, :test, :exps
    def initialize(d,t,e)
      @desc, @test, @exps = d,t,e
    end
    def inspect
      [@desc.inspect, @test.inspect, @exps.inspect].join
    end
    def run
      Tryouts.debug '-'*40, inspect
      #puts $/, "Passed #{results.select { |obj| obj == true}.size} of #{tests.size}"
    end
  end
  class Section < Array
    attr_accessor :first, :last
    def initialize start=0
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
    def inspect_debug
      range.to_a.zip(to_testcase).collect do |line|
        "%-4d %s\n" % line
      end.join
    end
    def to_s
      self.join $/
    end
    def to_testcase
      self
    end
  end
  
  @cases = []
  class << self
    attr_accessor :debug
    attr_reader :cases
    
    def try path
      lines = preparse(path)
      cases = parse(lines)
      cases.each { |t| t.run }
    end
    
    def preparse path
      debug "Loading #{path}"
      lines = File.readlines(path)
      lines
    end
    
    def parse lines
      skip_ahead = 0
      cases = []
      lines.size.times do |idx|
        skip_ahead -= 1 and next if skip_ahead > 0
        line = lines[idx].chomp
        #debug('%-4d %s' % [idx, line])
        if expectation? line
          offset = 0
          exps = Section.new idx+1
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
          buffer, desc = Section.new, Section.new
          test = Section.new(idx)  # test start the line before the exp. 
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
          
          cases << TestCase.new( desc, test, exps)
        end
      end
      cases
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

