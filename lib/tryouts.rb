# frozen_string_literal: true

require 'stringio'

TRYOUTS_LIB_HOME = __dir__ unless defined?(TRYOUTS_LIB_HOME)

require_relative 'tryouts/console'
require_relative 'tryouts/section'
require_relative 'tryouts/testbatch'
require_relative 'tryouts/testcase'
require_relative 'tryouts/version'

class Tryouts
  @debug = false
  @quiet = false
  @noisy = false
  @fails = false
  @container = Class.new
  @cases = []
  @sysinfo = nil
  @testcase_io = StringIO.new

  module ClassMethods
    attr_accessor :container, :quiet, :noisy, :fails
    attr_writer :debug
    attr_reader :cases, :testcase_io

    def sysinfo
      require 'sysinfo'
      @sysinfo ||= SysInfo.new
      @sysinfo
    end

    def debug? = @debug == true

    def update_load_path(lib_glob)
      Dir.glob(lib_glob).each { |dir| $LOAD_PATH.unshift(dir) }
    end

    def run_all *paths
      batches = paths.collect do |path|
        parse path
      end

      all = 0
      skipped_tests = 0
      failed_tests = 0
      skipped_batches = 0
      failed_batches = 0

      msg format('Ruby %s @ %-60s', RUBY_VERSION, Time.now), $/

      if Tryouts.debug?
        Tryouts.debug "Found #{paths.size} files:"
        paths.each { |path| Tryouts.debug "  #{path}" }
        Tryouts.debug
      end

      batches.each do |batch|
        path = batch.path.gsub(%r{#{Dir.pwd}/?}, '')
        divider = '-' * 70
        path_pretty = format('>>>>>  %-20s  %s', path, '').ljust(70, '<')

        msg $/
        vmsg Console.reverse(divider)
        vmsg Console.reverse(path_pretty)
        vmsg Console.reverse(divider)
        vmsg $/

        before_handler = proc do |tc|
          if Tryouts.noisy
            tc_title = tc.desc.to_s
            vmsg Console.underline(format('%-58s ', tc_title))
            vmsg tc.test.inspect, tc.exps.inspect
          end
        end

        batch.run(before_handler) do |tc|
          all += 1
          failed_tests += 1 if tc.failed?
          skipped_tests += 1 if tc.skipped?
          codelines = tc.outlines.join($/)
          first_exp_line = tc.exps.first
          result_adjective = tc.failed? ? 'FAILED' : 'PASSED'

          first_exp_line = tc.exps.first
          location = format('%s:%d', tc.exps.path, first_exp_line)

          expectation = Console.color(tc.color, codelines)
          summary = Console.color(tc.color, "%s @ %s" % [tc.adjective, location])
          vmsg '         %s' % expectation
          if tc.failed?
            msg Console.reverse(summary)
          else
            msg summary
          end
          vmsg

          # Output buffered testcase_io to stdout
          # and reset it for the next test case.
          unless Tryouts.fails && !tc.failed?
            $stdout.puts testcase_io.string unless Tryouts.quiet
          end

          # Reset the testcase IO buffer
          testcase_io.truncate(0)
        end
      end

      # Create a line of separation before the result summary
      msg $INPUT_RECORD_SEPARATOR  # newline

      if all
        suffix = "tests passed (#{skipped_tests} skipped)" if skipped_tests > 0
        actual_test_size = all - skipped_tests
        if actual_test_size > 0
          msg cformat(all - failed_tests - skipped_tests, all - skipped_tests, suffix)
        end
      end

      actual_batch_size = (batches.size - skipped_batches)
      if batches.size > 1 && actual_batch_size > 0
        suffix = 'batches passed'
        suffix << " (#{skipped_batches} skipped)" if skipped_batches > 0
        msg cformat(batches.size - skipped_batches - failed_batches, batches.size - skipped_batches, suffix)
      end

      # Print out the buffered result summary
      $stdout.puts testcase_io.string

      failed_tests  # returns the number of failed tests (0 if all passed)
    end

    def cformat(*args)
      Console.bright '%d of %d %s' % args
    end

    def run(path)
      batch = parse path
      batch.run
      batch
    end

    def parse(path)
      # debug "Loading #{path}"
      lines = File.readlines path
      skip_ahead = 0
      batch = TestBatch.new path, lines
      lines.size.times do |idx|
        skip_ahead -= 1 and next if skip_ahead > 0

        line = lines[idx].chomp
        # debug('%-4d %s' % [idx, line])
        next unless expectation? line

        offset = 0
        exps = Section.new(path, idx + 1)
        exps << line.chomp
        while idx + offset < lines.size
          offset += 1
          this_line = lines[idx + offset]
          break if ignore?(this_line)

          if expectation?(this_line)
            exps << this_line.chomp
            skip_ahead += 1
          end
          exps.last += 1
        end

        offset = 0
        buffer = Section.new(path)
        desc = Section.new(path)
        test = Section.new(path, idx) # test start the line before the exp.
        while idx - offset >= 0
          offset += 1
          this_line = lines[idx - offset].chomp
          buffer.unshift this_line if ignore?(this_line)
          buffer.unshift this_line if comment?(this_line)
          if test?(this_line)
            test.unshift(*buffer) && buffer.clear
            test.unshift this_line
          end
          if test_begin?(this_line)
            while test_begin?(lines[idx - (offset + 1)].chomp)
              offset += 1
              buffer.unshift lines[idx - offset].chomp
            end
          end
          next unless test_begin?(this_line) || idx - offset == 0 || expectation?(this_line)

          adjust = expectation?(this_line) ? 2 : 1
          test.first = idx - offset + buffer.size + adjust
          desc.unshift(*buffer)
          desc.last = test.first - 1
          desc.first = desc.last - desc.size + 1
          # remove empty lines between the description
          # and the previous expectation
          while !desc.empty? && desc[0].empty?
            desc.shift
            desc.first += 1
          end
          break
        end

        batch << TestCase.new(desc, test, exps)
      end

      batch
    end
    def print(str)
      return if Tryouts.quiet

      $stdout.print str
      $stdout.flush
    end

    def vmsg *msgs
      msg(*msgs) if Tryouts.noisy
    end

    def msg *msgs
      testcase_io.puts(*msgs) unless Tryouts.quiet
    end

    def err *msgs
      msg.each do |line|
        $stderr.puts Console.color :red, line
      end
    end

    def debug *msgs
      $stderr.puts(*msgs) if debug?
    end

    def eval(str, path, line)
      Kernel.eval str, @container.send(:binding), path, line
    rescue SyntaxError, LoadError => e
      Tryouts.err Console.color(:red, e.message),
                  Console.color(:red, e.backtrace.first)
      nil
    end

    private

    def expectation?(str)
      !ignore?(str) && str.strip.match(/\A\#+\s*=>/)
    end

    def comment?(str)
      !str.strip.match(/^\#+/).nil? && !expectation?(str)
    end

    def test?(str)
      !ignore?(str) && !expectation?(str) && !comment?(str)
    end

    def ignore?(str)
      str.to_s.strip.chomp.empty?
    end

    def test_begin?(str)
      !str.strip.match(/\#+\s*TEST/i).nil? ||
        !str.strip.match(/\A\#\#+[\s\w]+/i).nil?
    end
  end

  extend ClassMethods
end
