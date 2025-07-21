# lib/tryouts/console.rb

require 'pathname'

class Tryouts
  module Console
    # ANSI escape sequence numbers for text attributes
    unless defined? ATTRIBUTES
      ATTRIBUTES = {
        normal: 0,
        bright: 1,
        dim: 2,
        underline: 4,
        blink: 5,
        reverse: 7,
        hidden: 8,
        default: 0,
      }.freeze
    end

    # ANSI escape sequence numbers for text colours
    unless defined? COLOURS
      COLOURS = {
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
        default: 39,
        random: 30 + rand(10).to_i,
      }.freeze
    end

    # ANSI escape sequence numbers for background colours
    unless defined? BGCOLOURS
      BGCOLOURS = {
        black: 40,
        red: 41,
        green: 42,
        yellow: 43,
        blue: 44,
        magenta: 45,
        cyan: 46,
        white: 47,
        default: 49,
        random: 40 + rand(10).to_i,
      }.freeze
    end

    module InstanceMethods
      def bright
        Console.bright(self)
      end

      def underline
        Console.underline(self)
      end

      def reverse
        Console.reverse(self)
      end

      def color(col)
        Console.color(col, self)
      end

      def att(col)
        Console.att(col, self)
      end

      def bgcolor(col)
        Console.bgcolor(col, self)
      end
    end
    class << self
      def bright(str, io = $stdout)
        str = [style(ATTRIBUTES[:bright], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def underline(str, io = $stdout)
        str = [style(ATTRIBUTES[:underline], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def reverse(str, io = $stdout)
        str = [style(ATTRIBUTES[:reverse], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def color(col, str, io = $stdout)
        str = [style(COLOURS[col], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def att(name, str, io = $stdout)
        str = [style(ATTRIBUTES[name], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def bgcolor(col, str, io = $stdout)
        str = [style(ATTRIBUTES[col], io: io), str, default_style(io)].join
        str.extend Console::InstanceMethods
        str
      end

      def style(*att, io: $stdout)
        # Only output ANSI codes if writing to a TTY
        return '' unless io.respond_to?(:tty?) && io.tty?
        # => \e[8;34;42m
        "\e[%sm" % att.join(';')
      end

      def default_style(io = $stdout)
        style(ATTRIBUTES[:default], COLOURS[:default], BGCOLOURS[:default], io: io)
      end

      # Converts an absolute file path to a path relative to the current working
      # directory. This simplifies logging and error reporting by showing
      # only the relevant parts of file paths instead of lengthy absolute paths.
      #
      def pretty_path(file)
        return nil if file.nil?

        file     = File.expand_path(file) # be absolutely sure
        basepath = Dir.pwd
        Pathname.new(file).relative_path_from(basepath).to_s
      end
    end
  end
end
