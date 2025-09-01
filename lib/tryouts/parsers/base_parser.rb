# lib/tryouts/parsers/base_parser.rb

require 'prism'

require_relative 'shared_methods'
require_relative '../parser_warning'

class Tryouts
  # Fixed LegacyParser with pattern matching for robust token filtering
  module Parsers
    class BaseParser
      include Tryouts::Parsers::SharedMethods

      def initialize(source_path, options = {})
        @source_path  = source_path
        @source       = File.read(source_path)
        @lines        = @source.lines.map(&:chomp)
        @prism_result = Prism.parse(@source)
        @parsed_at    = Time.now
        @options      = options
        @warnings     = []
      end

    end
  end
end
