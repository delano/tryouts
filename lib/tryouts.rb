#require 'pathname'
#p Pathname(caller.last.split(':').first)
require 'ostruct'

class Tryouts
  @debug = false
  @container = Class.new
  @cases = []
  class << self
    attr_accessor :debug, :container
    attr_reader :cases
    
    def debug?() @debug == true end
    
    def run_all *paths
      batches = paths.collect do |path|
        run path
      end
      
      all, skipped_tests, failed_tests = 0, 0, 0
      skipped_batches, failed_batches = 0, 0
      
      msg 'Ruby %s @ %-40s' % [RUBY_VERSION, Time.now]
      
      batches.each do |batch|
        if !batch.run?
          skipped_batches += 1 
          status = "SKIP"
        elsif batch.failed?
          failed_batches += 1 
          status = Console.color(:red, "FAIL").bright
        else
          status = Console.color(:green, "PASS").bright
        end
        
        path = batch.path.gsub(/#{Dir.pwd}\/?/, '')
        
        msg '%-60s %s' % [path, status]
        batch.each do |t|
          if t.failed? && failed_tests == 0
            #msg Console.reverse(" %-60s" % 'Errors')
          end
          
          all += 1
          skipped_tests += 1 unless t.run?

          if t.failed?
            msg if (failed_tests += 1) == 1
            msg Console.reverse(' %-58s ' % [t.desc.to_s])
            msg t.test.inspect, t.exps.inspect
            msg Console.color(:red, t.failed.join($/)), $/
          end
        end
      end
      msg
      if all > 0
        suffix = 'tests passed'
        suffix << " (#{skipped_tests} skipped)" if skipped_tests > 0
        msg cformat(all-failed_tests-skipped_tests, all-skipped_tests, suffix) if all-skipped_tests > 0
      end
      if batches.size > 1
        if batches.size-skipped_batches > 0
          suffix = "batches passed"
          suffix << " (#{skipped_batches} skipped)" if skipped_batches > 0
          msg cformat(batches.size-skipped_batches-failed_batches, batches.size-skipped_batches, suffix)
        end  
      end
      
      failed_tests # 0 means success
    end
    
    def cformat(*args)
      Console.bright '%3d of %d %s' % args
    end
    
    def run path
      batch = parse path
      batch.run
      batch
    end
    
    def parse path
      #debug "Loading #{path}"
      lines = File.readlines path
      skip_ahead = 0
      batch = TestBatch.new path, lines
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
              exps << this_line.chomp
              skip_ahead += 1
            end
            exps.last += 1
          end
          
          offset = 0
          buffer, desc = Section.new(path), Section.new(path)
          test = Section.new(path, idx)  # test start the line before the exp. 
          blank_buffer = Section.new(path)
          while (idx-offset >= 0)
            offset += 1
            this_line = lines[idx-offset].chomp
            buffer.unshift this_line if ignore?(this_line)
            if comment?(this_line)
              buffer.unshift this_line 
            end
            if test?(this_line)
              test.unshift(*buffer) && buffer.clear
              test.unshift this_line
            end
            if test_begin?(this_line)
              while test_begin?(lines[idx-(offset+1)].chomp)
                offset += 1
                buffer.unshift lines[idx-offset].chomp
              end
            end
            if test_begin?(this_line) || idx-offset == 0 || expectation?(this_line)
              adjust = expectation?(this_line) ? 2 : 1
              test.first = idx-offset+buffer.size+adjust
              desc.unshift *buffer
              desc.last = test.first-1
              desc.first = desc.last-desc.size+1
              # remove empty lines between the description 
              # and the previous expectation
              while !desc.empty? && desc[0].empty? 
                desc.shift
                desc.first += 1
              end
              break 
            end
          end
          
          batch << TestCase.new(desc, test, exps)
        end
      end

      batch
    end
    
    def print str
      STDOUT.print str
      STDOUT.flush
    end
    
    def msg *msg
      STDOUT.puts *msg
    end
    
    def err *msg
      msg.each do |line|
        STDERR.puts Console.color :red, line
      end
    end
    
    def debug *msg
      STDERR.puts *msg if @debug
    end
    
    def eval(str, path, line)
      begin
        Kernel.eval str, @container.send(:binding), path, line
      rescue SyntaxError, LoadError => ex
        Tryouts.err Console.color(:red, ex.message),
                    Console.color(:red, ex.backtrace.first)
        nil
      end
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
      ret = !str.strip.match(/^\#+\s*TEST/i).nil? ||
      !str.strip.match(/^\#\#+[\s\w]+/i).nil?
      ret
    end

    
  end
  
  class TestBatch < Array
    class Container
      def metaclass
        class << self; end
      end
    end
    attr_reader :path
    attr_reader :failed
    attr_reader :lines
    def initialize(p,l)
      @path, @lines = p, l
      @container = Container.new.metaclass
      @run = false
    end
    def run
      return if empty?
      setup
      ret = self.select { |tc| !tc.run } # select failed
      @failed = ret.size
      @run = true
      clean
      !failed?
    end
    def failed?
       !@failed.nil? && @failed > 0
    end
    def setup
      return if empty?
      start = first.desc.nil? ? first.test.first : first.desc.first-1
      Tryouts.eval lines[0..start-1].join, path, 0 if start > 0
    end
    def clean
      return if empty?
      last = first.exps.last+1
      if last < lines.size
        Tryouts.eval lines[last..-1].join, path, last
      end
    end
    def run?
      @run
    end
  end
  class TestCase
    attr_reader :desc, :test, :exps, :failed, :passed
    def initialize(d,t,e)
      @desc, @test, @exps, @path = d,t,e
    end
    def inspect
      [@desc.inspect, @test.inspect, @exps.inspect].join
    end
    def to_s
      [@desc.to_s, @test.to_s, @exps.to_s].join
    end
    def run
      Tryouts.debug '%s:%d' % [@test.path, @test.first]
      Tryouts.debug inspect, $/
      test_value = Tryouts.eval @test.to_s, @test.path, @test.first
      @passed, @failed = [], []
      exps.each_with_index { |exp,idx| 
        exp =~ /\#+\s*=>\s*(.+)$/
        exp_value = Tryouts.eval($1, @exps.path, @exps.first+idx)
        ret = test_value == exp_value
        if ret
          @passed << '     %s == %s' % [test_value.inspect, exp_value.inspect] 
        else
          @failed << '     %s != %s' % [test_value.inspect, exp_value.inspect] 
        end
        ret
      }
      Tryouts.debug
      @failed.empty?
    end
    def run?
      !@failed.nil?
    end
    def failed?
      !@failed.nil? && !@failed.empty?
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
      self.join($/)
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
    
    module InstanceMethods
      def bright
        Console.bright(self)
      end
      def reverse
        Console.reverse(self)
      end
      def color(col)
        Console.color(col, self)
      end
      def att(col)
        Console.att(col, self)
      end
      def bgcolor(col)
        Console.bgcolor(col, self)
      end
    end
    
    def self.bright(str)
      str = [style(ATTRIBUTES[:bright]), str, default_style].join
      str.extend Console::InstanceMethods
      str
    end
    def self.reverse(str)
      str = [style(ATTRIBUTES[:reverse]), str, default_style].join
      str.extend Console::InstanceMethods
      str
    end
    def self.color(col, str)
      str = [style(COLOURS[col]), str, default_style].join
      str.extend Console::InstanceMethods
      str
    end
    def self.att(name, str)
      str = [style(ATTRIBUTES[name]), str, default_style].join
      str.extend Console::InstanceMethods
      str
    end
    def self.bgcolor(col, str)
      str = [style(ATTRIBUTES[col]), str, default_style].join
      str.extend Console::InstanceMethods
      str
    end
    private
    def self.style(*att)
      # => \e[8;34;42m
      "\e[%sm" % att.join(';')
    end
    def self.default_style
      style(ATTRIBUTES[:default], ATTRIBUTES[:COLOURS], ATTRIBUTES[:BGCOLOURS])
    end
  end

end

