#require 'pathname'
#p Pathname(caller.last.split(':').first)
require 'ostruct'

class Tryouts
  @debug = false
  
  @cases = []
  class << self
    attr_accessor :debug
    attr_reader :cases
    
    def run_all *paths
      batches = paths.collect do |path|
        run path
      end
      msg
      all, skipped, failed_batches, failed_tests = 0, 0, 0, 0
      batches.each do |batch|
        failed_batches += 1 if batch.failed?
        batch.each do |t|
          
          all += 1
          skipped += 1 unless t.run?

          if t.failed?
            msg if (failed_tests += 1) == 1
            msg t.test.path
            msg Console.color(:red, '-'*40)
            msg Console.color(:red, t.inspect)
          end
        end
      end
      if batches.size > 1
        msg cformat('batches', batches.size-failed_batches, batches.size, :passed)
      end
      
      msg cformat(all-failed_tests, all, 'tests passed') if all-skipped > 0
      msg cformat(skipped, all, 'tests skipped') if skipped > 0
      
      failed_batches == 0
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
      debug "Loading #{path}"
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
    
    def self.bright(str)
      [style(ATTRIBUTES[:bright]), str, default_style].join
    end
    def self.color(col, str)
      [style(COLOURS[col]), str, default_style].join
    end
    def self.style(*att)
      # => \e[8;34;42m
      "\e[%sm" % att.join(';')
    end
    def self.default_style
      style(ATTRIBUTES[:default], ATTRIBUTES[:COLOURS], ATTRIBUTES[:BGCOLOURS])
    end
  end
  
  class TestBatch < Array
    attr_reader :path
    attr_reader :failed
    attr_reader :lines
    def initialize(p,l)
      @path, @lines = p, l
    end
    def run
      begin
        setup
      rescue SyntaxError, LoadError => ex
        Tryouts.err Console.color(:red, ex.message),
                    Console.color(:red, ex.backtrace.first)
        return @failed = size
      end
      ret = self.select { |tc| !tc.run } # select failed
      @failed = ret.size unless ret.empty?
      begin
        clean
      rescue SyntaxError, LoadError => ex
        Tryouts.err Console.color(:red, ex.message),
                    Console.color(:red, ex.backtrace.first)
        return @failed = size
      end
      !failed?
    end
    def failed?
       !@failed.nil? && @failed > 0
    end
    def setup
      start = first.desc.first-1
      if start > 0
        eval(lines[0..start-1].join, binding, path, 1)
      end
    end
    def clean
      last = first.exps.last+1
      if last < lines.size
        eval(lines[last..-1].join, binding, path, last)
      end
    end
    def run?
      !@failed.nil?
    end
  end
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
    def test_proc
      create_proc @test.join("#{$/}  "), @test.path, @test.first
    end
    def exps_procs
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
      test_value = @container.class.module_eval &test_proc
      results = exps_procs.collect { |exp| 
        ret = test_value == @container.class.module_eval(&exp) 
        color = ret ? :green : :red
        Tryouts.print Console.color(color, '.')
        ret
      }
      Tryouts.debug
      @success = results.uniq == [true]
    end
    def run?
      !@success.nil?
    end
    def failed?
      !@success.nil? && @success != true
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
end

