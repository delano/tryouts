# try/core/top_level_scope_try.rb
#
# frozen_string_literal: true

# A tryouts file runs at the top level, like `ruby file.rb`: classes it
# defines are ordinary top-level classes, reopening a core class patches the
# real one, and self is a main object. A top-level `def` belongs to that main
# object, so it never lands on Object for other code to trip over. The
# constants a file defines are removed when it finishes, and in fresh context
# after each test.

require 'fileutils'
require 'shellwords'
require 'tempfile'
require_relative '../../lib/tryouts'

class Integer
  def to_minutes_label
    "#{self} min"
  end
end

def default_port
  8080
end

def format(cents)
  "$#{cents / 100}.#{(cents % 100).to_s.rjust(2, '0')}"
end

class ScopeTryServer
  def initialize(port)
    @port = port
  end

  attr_reader :port
end

ServerConfig = Struct.new(:host, :port)

def scope_try_statuses(source, shared:, name: 'scope')
  file = Tempfile.new([name, '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: shared)
  batch.run
  batch.results.map(&:status)
ensure
  file&.close!
end

point_class = <<~'RUBY'
  require 'shellwords'

  class ScopeTryPoint < Struct.new(:x, :y)
    def sum = x + y
  end

  ## first
  ScopeTryPoint.new(1, 2).sum
  #=> 3

  ## second
  ScopeTryPoint.new(2, 2).sum
  #=> 4
RUBY

## Reopening a core class patches the real class
25.to_minutes_label
#=> '25 min'

## A class defined in the file has its plain name
ScopeTryServer.name
#=> 'ScopeTryServer'

## A top-level method is callable from the file's code and its blocks
ScopeTryServer.new(default_port).port
#=> 8080

## A top-level method does not become a method of Object
Object.method_defined?(:default_port) || Object.private_method_defined?(:default_port)
#=> false

## A top-level method does not shadow a Kernel method for other objects
[format(1250), 5.method(:format).owner]
#=> ['$12.50', Kernel]

## A top-level method can be made private, as in a script
private def tidy(text) = text.strip
[tidy('  done  '), respond_to?(:tidy)]
#=> ['done', false]

## Objects of a class defined in the file can be marshalled
Marshal.load(Marshal.dump(ServerConfig.new('localhost', 3000)))
#=> ServerConfig.new('localhost', 3000)

## Libraries can look the class up by name
Object.const_get('ScopeTryServer')
#=> ScopeTryServer

## The file starts at the top-level nesting, outside any method
[Module.nesting, __method__]
#=> [[], nil]

## self prints as main, as in a script
[to_s, inspect]
#=> ['main', 'main']

## Top-level include mixes into Object
include FileUtils
Object.include?(FileUtils)
#=> true

## Top-level using is refused with an explanation
using Module.new
#=!> RuntimeError
#=~> /inside a class or module body/

## Fresh context gives each test its own self, shared context one per file
selves = <<~'RUBY'
  ## first test
  $scope_try_selves << object_id
  #=*>

  ## second test
  $scope_try_selves << object_id
  #=*>
RUBY
$scope_try_selves = []
scope_try_statuses(selves, shared: false)
fresh_ids = $scope_try_selves.uniq.size
$scope_try_selves = []
scope_try_statuses(selves, shared: true)
[fresh_ids, $scope_try_selves.uniq.size]
#=> [2, 1]

## Fresh context runs a setup that subclasses Struct.new before every test
scope_try_statuses(point_class, shared: false)
#=> [:passed, :passed]

## Two files in one run may define the same class
[scope_try_statuses(point_class, shared: true, name: 'first'), scope_try_statuses(point_class, shared: true, name: 'second')]
#=> [[:passed, :passed], [:passed, :passed]]

## The file's constants are gone when it finishes, a required library's stay
scope_try_statuses(point_class, shared: true)
[Object.const_defined?(:ScopeTryPoint), Object.const_defined?(:Shellwords)]
#=> [false, true]

$scope_try_selves = nil
