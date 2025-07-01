require 'pathname'
require 'tree_sitter'

unless defined?(TRYOUTS_LIB_HOME)
  TRYOUTS_LIB_HOME = File.expand_path File.dirname(__FILE__)
end

require_relative 'tryouts/helpers'
require_relative 'tryouts/version'
require_relative 'tryouts/models'
require_relative 'tryouts/parser'

class Tryouts
  @debug = false
  @quiet = false
  @noisy = false
  @container = Class.new
  @cases = []
  @sysinfo = nil

  class << self
    attr_accessor :debug, :container, :quiet, :noisy
    attr_reader :cases, :parser, :path, :tree
  end

  attr_reader :path, :parser, :testrun

  def initialize(path)
    @path = path
    @parser = Tryouts::Parser.new(path)
    @testrun = @parser.parse
  end

  def run
    @parser.run
    self
  end

  def report
    return puts(@parser.report) unless self.class.quiet

    # In quiet mode, only show failures
    failed_results = @parser.results.reject(&:success?)
    return if failed_results.empty?

    output = []
    output << "\nFailures:"
    output << "--------"

    failed_results.each_with_index do |result, index|
      output << "\n#{index + 1}) #{result.test_case.description}"
      if result.error
        output << "  Error: #{result.error.class}: #{result.error.message}"
      else
        output << "  Expected: #{result.test_case.expectations.join(', ')}"
        output << "  Got: #{result.result}"
      end
    end

    puts output.flatten.join("\n")
  end

  def failed_count
    return 0 unless @parser.results
    @parser.results.count { |r| !r.success? }
  end

  module ClassMethods
    def sysinfo
      require 'sysinfo'
      @sysinfo ||= SysInfo.new
      @sysinfo
    end

    def debug?
      @debug == true
    end
  end

  extend ClassMethods
end
