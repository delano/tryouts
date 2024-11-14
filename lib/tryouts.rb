require 'pathname'
#require 'tree_stand'
require 'tree_sitter'

unless defined?(TRYOUTS_LIB_HOME)
  TRYOUTS_LIB_HOME = File.expand_path File.dirname(__FILE__)
end

require_relative 'tryouts/helpers'
require_relative 'tryouts/version'
require_relative 'tryouts/parser'

module Tryouts
  @debug = false
  @quiet = false
  @noisy = false
  @container = Class.new
  @cases = []
  @sysinfo = nil

  class << self
    attr_accessor :debug, :container, :quiet, :noisy
    attr_reader :cases
  end

  module ClassMethods

    def sysinfo
      require 'sysinfo'
      @sysinfo ||= SysInfo.new
      @sysinfo
    end

    def debug?() @debug == true end
  end

  extend ClassMethods
end
