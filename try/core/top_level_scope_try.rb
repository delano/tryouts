# try/core/top_level_scope_try.rb
#
# frozen_string_literal: true

# A tryouts file runs at the top level, like `ruby file.rb`: classes and
# methods it defines are ordinary top-level definitions, and reopening a
# core class patches the real one.

require 'fileutils'
require 'stringio'
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

class ScopeTryServer
  def port
    default_port
  end
end

ServerConfig = Struct.new(:host, :port)

def scope_try_statuses(source, shared:)
  file = Tempfile.new(['scope', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: shared)
  batch.run
  batch.results.map(&:status)
ensure
  file&.close!
end

## Reopening a core class patches the real class
25.to_minutes_label
#=> '25 min'

## A class defined in the file has its plain name
ScopeTryServer.name
#=> 'ScopeTryServer'

## A class defined in the file can call a top-level method
ScopeTryServer.new.port
#=> 8080

## Objects of a class defined in the file can be marshalled
Marshal.load(Marshal.dump(ServerConfig.new('localhost', 3000)))
#=> ServerConfig.new('localhost', 3000)

## Libraries can look the class up by name
Object.const_get('ScopeTryServer')
#=> ScopeTryServer

## The file starts at the top-level nesting
Module.nesting
#=> []

## Top-level include works as in a script
include FileUtils
respond_to?(:mkdir_p, true)
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

## Re-running code that assigns a constant does not warn while quieted
code = Tryouts::ScriptBinding.create
code.eval('SCOPE_TRY_RETRIES = 3')
previous_stderr = $stderr
quieted = $stderr = StringIO.new
Tryouts::ScriptBinding.quiet_redefinitions { code.eval('SCOPE_TRY_RETRIES = 3') }
warned = $stderr = StringIO.new
code.eval('SCOPE_TRY_RETRIES = 3')
$stderr = previous_stderr
[quieted.string, warned.string.include?('already initialized constant SCOPE_TRY_RETRIES')]
#=> ['', true]

$scope_try_selves = nil
