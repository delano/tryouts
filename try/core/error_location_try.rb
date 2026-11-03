# try/core/error_location_try.rb
#
# frozen_string_literal: true

# A test that raises is reported at the line inside the test that led to the
# error, even when the exception comes from a helper defined in the setup.

require 'tempfile'
require_relative '../../lib/tryouts'

def error_lines(source)
  file = Tempfile.new(['location', '_try.rb'])
  file.write(source)
  file.flush

  testrun = Tryouts::StatementParser.new(file.path).parse
  batch   = Tryouts::TestBatch.new(testrun, shared_context: true)
  batch.run
  batch.results.map { |result| result.failure_line + 1 }
ensure
  file&.close!
end

## A helper from the setup that raises is reported at the test's call
error_lines(<<~'RUBY')
  require 'json'

  def parse_config(text)
    JSON.parse(text)
  end

  ## invalid config
  input = '{"a": '
  parse_config(input)
  #=> { 'a' => 1 }
RUBY
#=> [9]

## An error raised by the test's own code is reported where it was raised
error_lines(<<~'RUBY')
  ## nil has no upcase
  value = nil
  value.upcase
  #=> 'X'
RUBY
#=> [3]
