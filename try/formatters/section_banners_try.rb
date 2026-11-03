# try/formatters/section_banners_try.rb
#
# frozen_string_literal: true

# Verbose output names the setup and teardown by their file lines, counting
# from 1 like the test listings and --inspect.

require 'stringio'
require 'tmpdir'
require_relative '../../lib/tryouts'

def verbose_output(source, **options)
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'cart_try.rb')
    File.write(path, source)
    out = StringIO.new
    Tryouts::CLI.new.run([path], verbose: true, stdout: out, stderr: out, **options)
    out.string
  end
end

cart = <<~'RUBY'
  @cart = []
  puts 'setup'

  ## add one item
  @cart << :apple
  @cart.size
  #=> 1

  puts "teardown #{@cart.size}"
RUBY

## The setup banner names file lines 1..2
verbose_output(cart)[/Executing global setup \(lines [^)]+\)/]
#=> "Executing global setup (lines 1..2)"

## The teardown banner names file line 9
verbose_output(cart)[/Executing teardown \(lines [^)]+\)/]
#=> "Executing teardown (lines 9..9)"

## Fresh context prints the same 1-based ranges
verbose_output(cart, shared_context: false).scan(/\(lines [^)]+\)/)
#=> ["(lines 1..2)", "(lines 9..9)"]
