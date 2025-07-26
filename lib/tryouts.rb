# lib/tryouts.rb



require 'stringio'
require 'timeout'

TRYOUTS_LIB_HOME = __dir__ unless defined?(TRYOUTS_LIB_HOME)

require_relative 'tryouts/console'
require_relative 'tryouts/test_batch'
require_relative 'tryouts/version'
require_relative 'tryouts/prism_parser'
require_relative 'tryouts/cli'

class Tryouts
  @debug       = false
  @quiet       = false
  @noisy       = false
  @fails       = false
  @container   = Class.new
  @cases       = [] # rubocop:disable ThreadSafety/MutableClassInstanceVariable
  @testcase_io = StringIO.new

  module ClassMethods
    attr_accessor :container, :quiet, :noisy, :fails
    attr_writer :debug
    attr_reader :cases, :testcase_io

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

    def debug(msg, indent: 0)
      return unless debug?

      prefix = ('  ' * indent) + Console.color(:cyan, 'DEBUG')
      warn "#{prefix} #{msg}"
    end

    # Error classification for resilient error handling
    def classify_error(exception)
      case exception
      when SystemExit, SignalException
        :non_recoverable_exit
      when Timeout::Error
        :transient
      when Errno::ENOENT, Errno::EACCES, Errno::EPERM
        :file_system
      when LoadError, NameError, NoMethodError
        :code_structure
      when SecurityError, NoMemoryError, SystemStackError
        :system_resource
      when SyntaxError, TryoutSyntaxError
        :syntax
      when StandardError
        :recoverable
      else
        :unknown
      end
    end

    # Determine if an error should stop batch execution
    def batch_stopping_error?(exception)
      classification = classify_error(exception)
      [:non_recoverable_exit, :system_resource, :syntax].include?(classification)
    end

    # Determine if an error should stop individual test execution
    def test_stopping_error?(exception)
      classification = classify_error(exception)
      [:non_recoverable_exit, :system_resource].include?(classification)
    end
  end

  extend ClassMethods
end
