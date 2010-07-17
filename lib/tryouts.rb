#require 'pathname'
#p Pathname(caller.last.split(':').first)
require 'ostruct'

class Tryouts
  @debug = false
  class Container; end
  class Section < OpenStruct; end
  class Expectation 
    attr_accessor :path, :line, :body, :expected_values, :desc, :container
    attr_reader :results, :tests
    attr_accessor :ret, :exp
    def initialize(path, line, body, *expected_values)
      @path, @line = path, line
      @body, @expected_values = body, expected_values
      @tests = []
    end
    def run_all
      @results = expected_values.collect do |expectation|
        sself = self
        @container.class.module_eval do
          sself.ret = eval(sself.body, binding, sself.path, sself.line)
          sself.exp = eval(expectation, binding, sself.path, sself.line)
        end
        @tests << [ret, exp]
        ret == exp
      end
    end
    def success?
      !@results.nil?  && @results.uniq == [true]
    end
  end
  
  class << self
    attr_accessor :debug
    
    def try path
      lines = preparse(path)
      source = parse(lines)
      
      #puts $/, "Passed #{results.select { |obj| obj == true}.size} of #{tests.size}"
    end
    
    def preparse path
      debug "Loading #{path}"
      lines = File.readlines(path)
      lines
    end
    
    def parse lines
      skip_ahead = 0
      lines.size.times do |idx|
        skip_ahead -= 1 and next if skip_ahead > 0
        line = lines[idx]
        #debug('%-4d %s' % [idx, line])
        if expectation? line
          offset = 0
          
          exps = [line]
          # TODO: grab all expectations
          while (idx+offset < lines.size)
            offset += 1
            this_line = lines[idx+offset]
            break if ignore?(this_line)
            if expectation?(this_line)
              exps << this_line 
              skip_ahead += 1
            end
          end
          
          offset = 0
          buffer, test, desc = [], [], []
          while (idx-offset >= 0)
            offset += 1
            this_line = lines[idx-offset]
            next if ignore?(this_line)
            buffer.unshift this_line if comment?(this_line)
            if test_content?(this_line)
              test.unshift(*buffer) && buffer.clear
              test.unshift this_line
            end
            if expectation?(this_line) || idx-offset == 0
              desc.unshift *buffer
              break 
            end
          end
          
          debug('---------------------------')
          debug(*desc)
          debug(*test)
          debug(*exps)
        end
      end
      
    end

    private
    
    def expectation? str
      !ignore?(str) && str.strip.match(/^\#\s*=>/)
    end
    
    def comment? str
      !str.strip.match(/^\#/).nil? && !expectation?(str)
    end
    
    def test_content? str
      !ignore?(str) && !expectation?(str) && !comment?(str)
    end
    
    def ignore? str
      str.strip.chomp.empty? 
    end
    
    
    def msg *msg
      STDOUT.puts *msg
    end
    
    def debug *msg
      STDERR.puts *msg if @debug
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

