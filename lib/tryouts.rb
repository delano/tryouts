# lib/tryouts.rb

# Coverage tracking
if ENV['COVERAGE'] || ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start
end

require 'stringio'

TRYOUTS_LIB_HOME = __dir__ unless defined?(TRYOUTS_LIB_HOME)

require_relative 'tryouts/console'
require_relative 'tryouts/section'
require_relative 'tryouts/testbatch'
require_relative 'tryouts/version'
require_relative 'tryouts/data_structures'
require_relative 'tryouts/prism_parser'
require_relative 'tryouts/cli'

class Tryouts
  @debug       = false
  @quiet       = false
  @noisy       = false
  @fails       = false
  @container   = Class.new
  @cases       = []
  @sysinfo     = nil
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

    def debug?
      @debug == true
    end

    def update_load_path(lib_glob)
      Dir.glob(lib_glob).each { |dir| $LOAD_PATH.unshift(dir) }
    end

    def trace(msg, indent: 0)
      return unless debug?

      prefix = ('  ' * indent) + Console.color(:dim, 'TRACE')
      warn "#{prefix} #{msg}"
    end
  end

  extend ClassMethods
end
