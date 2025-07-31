# try/formatters/console_formatting_try.rb
# Tests for Console module ANSI colors and formatting
require_relative '../test_helper'
require_relative '../../lib/tryouts/console'

## TEST: ANSI color constants are defined
Tryouts::Console::COLOURS.keys.include?(:red)
#=> true

Tryouts::Console::COLOURS[:red]
#=> 31

## TEST: Green color has correct ANSI code
Tryouts::Console::COLOURS[:green]
#=> 32

## TEST: Blue color has correct ANSI code
Tryouts::Console::COLOURS[:blue]
#=> 34

## TEST: ANSI attribute constants are defined
Tryouts::Console::ATTRIBUTES[:bright]
#=> 1

## TEST: Dim attribute has correct ANSI code
Tryouts::Console::ATTRIBUTES[:dim]
#=> 2

## TEST: Underline attribute has correct ANSI code
Tryouts::Console::ATTRIBUTES[:underline]
#=> 4

## TEST: Background color constants are defined
Tryouts::Console::BGCOLOURS[:red]
#=> 41

## TEST: Background green color has correct ANSI code
Tryouts::Console::BGCOLOURS[:green]
#=> 42

## TEST: Color formatting works
Tryouts::Console.color(:red, 'test')
#=> "\e[31mtest\e[0;39;49m"

## TEST: Green color formatting works
Tryouts::Console.color(:green, 'success')
#=> "\e[32msuccess\e[0;39;49m"

## TEST: Bright formatting works
Tryouts::Console.bright('test')
#=> "\e[1mtest\e[0;39;49m"

## TEST: Underline formatting works
Tryouts::Console.underline('test')
#=> "\e[4mtest\e[0;39;49m"

## TEST: Reverse formatting works
Tryouts::Console.reverse('test')
#=> "\e[7mtest\e[0;39;49m"

## TEST: Attribute formatting works
Tryouts::Console.att(:dim, 'test')
#=> "\e[2mtest\e[0;39;49m"

## TEST: Instance methods work via extension
result = Tryouts::Console.color(:blue, 'test')
result.bright
#=> "\e[1m\e[34mtest\e[0;39;49m\e[0;39;49m"

## TEST: Chaining instance methods
result = Tryouts::Console.color(:red, 'test')
result.underline.bright
#=> "\e[1m\e[4m\e[31mtest\e[0;39;49m\e[0;39;49m\e[0;39;49m"

## TEST: Style method creates ANSI escape sequences
Tryouts::Console.style(1, 31)
#=> "\e[1;31m"

## TEST: Style method combines multiple ANSI codes
Tryouts::Console.style(4, 32, 41)
#=> "\e[4;32;41m"

## TEST: Default style resets formatting
Tryouts::Console.default_style
#=> "\e[0;39;49m"

## TEST: pretty_path with nil input
Tryouts::Console.pretty_path(nil)
#=> nil

## TEST: pretty_path with simple filename
test_file = File.expand_path('test_file.rb')
result    = Tryouts::Console.pretty_path(test_file)
result
#=> "test_file.rb"

## TEST: pretty_path removes absolute path prefix
test_file = '/some/absolute/path/file.rb'
result    = Tryouts::Console.pretty_path(test_file)
result.end_with?('file.rb')
#=> true

## TEST: pretty_path handles nested paths
# Test that it creates relative paths correctly
test_file = File.expand_path('lib/tryouts/console.rb')
result    = Tryouts::Console.pretty_path(test_file)
result.include?('console.rb')
#=> true

## TEST: Random color generates valid color codes
random_color = Tryouts::Console::COLOURS[:random]
(30..39).include?(random_color)
#=> true

## TEST: Random background color generates valid codes
random_bg = Tryouts::Console::BGCOLOURS[:random]
(40..49).include?(random_bg)
#=> true
