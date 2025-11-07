# lib/tryouts/console.rb
#
# frozen_string_literal: true

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

      def style(*att, io: nil)
        # Only output ANSI codes if colors are supported
        target_io = io || $stdout

        # Explicit color control via environment variables
        # FORCE_COLOR/CLICOLOR_FORCE override NO_COLOR
        return "\e[%sm" % att.join(';') if ENV['FORCE_COLOR'] || ENV['CLICOLOR_FORCE']
        return '' if ENV['NO_COLOR']

        # Check if we're outputting to a real TTY
        tty_output = (target_io.respond_to?(:tty?) && target_io.tty?) ||
                     ($stdout.respond_to?(:tty?) && $stdout.tty?) ||
                     ($stderr.respond_to?(:tty?) && $stderr.tty?)

        # If we have a real TTY, always use colors
        return "\e[%sm" % att.join(';') if tty_output

        # For environments like Claude Code where TTY detection fails but we want colors
        # Check if output appears to be redirected to a file/pipe
        if ENV['TERM'] && ENV['TERM'] != 'dumb'
          # Check if stdout/stderr look like they're redirected using file stats
          begin
            stdout_stat = $stdout.stat
            stderr_stat = $stderr.stat

            # If either stdout or stderr looks like a regular file or pipe, disable colors
            stdout_redirected = stdout_stat.file? || stdout_stat.pipe?
            stderr_redirected = stderr_stat.file? || stderr_stat.pipe?

            # Enable colors if neither appears redirected
            return "\e[%sm" % att.join(';') unless stdout_redirected || stderr_redirected
          rescue StandardError
            # If stat fails, fall back to enabling colors with TERM set
            return "\e[%sm" % att.join(';')
          end
        end

        # Default: no colors
        ''
      end

      def default_style(io = $stdout)
        style(ATTRIBUTES[:default], COLOURS[:default], BGCOLOURS[:default], io: io)
      end

      # Converts an absolute file path to a path relative to the current working
      # directory. This simplifies logging and error reporting by showing
      # only the relevant parts of file paths instead of lengthy absolute paths.
      #
      def pretty_path(filepath)
        return nil if filepath.nil? || filepath.empty?

        basepath = Dir.pwd
        begin
          relative_path = Pathname.new(filepath).relative_path_from(basepath)
          if relative_path.to_s.start_with?('..')
            File.basename(filepath)
          else
            relative_path.to_s
          end
        rescue ArgumentError
          # Handle cases where filepath cannot be relativized (e.g., empty paths, different roots)
          File.basename(filepath)
        end
      end

      # Format backtrace entries with pretty file paths
      def pretty_backtrace(backtrace, limit: 10)
        return [] unless backtrace&.any?

        backtrace.first(limit).map do |frame|
          # Split the frame to get file path and line info
          # Use non-greedy match and more specific pattern to prevent ReDoS
          if frame.match(/^([^:]+(?::[^:0-9][^:]*)*):(\d+):(.*)$/)
            file_part = $1
            line_part = $2
            method_part = $3
            pretty_file = pretty_path(file_part) || File.basename(file_part)
            "#{pretty_file}:#{line_part}#{method_part}"
          else
            frame
          end
        end
      end
    end
  end
end
