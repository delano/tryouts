# lib/tryouts/parsers/base_parser.rb
#
# frozen_string_literal: true

require 'prism'

require_relative 'shared_methods'
require_relative '../parser_warning'

class Tryouts
  module Parsers
    # Base class for all tryout parsers providing common functionality
    #
    # BaseParser establishes the foundation for parsing tryout files by handling
    # file loading, Prism integration, and providing shared parsing infrastructure.
    # All concrete parser implementations (EnhancedParser, LegacyParser) inherit
    # from this class.
    #
    # @abstract Subclass and implement {#parse} to create a concrete parser
    # @example Implementing a custom parser
    #   class MyCustomParser < Tryouts::Parsers::BaseParser
    #     def parse
    #       # Your parsing logic here
    #       # Must return a Tryouts::Testrun object
    #     end
    #
    #     private
    #
    #     def parser_type
    #       :custom
    #     end
    #   end
    #
    # @!attribute [r] source_path
    #   @return [String] Path to the source file being parsed
    # @!attribute [r] source
    #   @return [String] Raw source code content
    # @!attribute [r] lines
    #   @return [Array<String>] Source lines with line endings removed
    # @!attribute [r] prism_result
    #   @return [Prism::ParseResult] Result of parsing source with Prism
    # @!attribute [r] parsed_at
    #   @return [Time] Timestamp when parsing was initiated
    # @!attribute [r] options
    #   @return [Hash] Parser configuration options
    # @!attribute [r] warnings
    #   @return [Array<Tryouts::ParserWarning>] Collection of parsing warnings
    #
    # ## Shared Functionality
    #
    # ### 1. File and Source Management
    # - Automatic file reading and line splitting
    # - UTF-8 encoding handling
    # - Path normalization and validation
    #
    # ### 2. Prism Integration
    # - Automatic Prism parsing of source code
    # - Syntax error detection and handling
    # - AST access for advanced parsing needs
    #
    # ### 3. Warning System
    # - Centralized warning collection and management
    # - Type-safe warning objects with context
    # - Integration with output formatters
    #
    # ### 4. Shared Methods
    # - Token grouping and classification logic
    # - Test case boundary detection
    # - Common utility methods for all parsers
    #
    # ## Parser Requirements
    #
    # Concrete parser implementations must:
    # 1. Implement the abstract `parse` method
    # 2. Return a `Tryouts::Testrun` object
    # 3. Handle syntax errors appropriately
    # 4. Provide a unique `parser_type` identifier
    #
    # @see EnhancedParser For Prism-based comment extraction
    # @see LegacyParser For line-by-line parsing approach
    # @see SharedMethods For common parsing utilities
    # @since 3.0.0
    class BaseParser
      include Tryouts::Parsers::SharedMethods

      # Initialize a new parser instance
      #
      # @param source_path [String] Absolute path to the tryout source file
      # @param options [Hash] Configuration options for parsing behavior
      # @option options [Boolean] :strict Enable strict mode validation
      # @option options [Boolean] :warnings Enable warning collection (default: true)
      # @raise [Errno::ENOENT] If source file doesn't exist
      # @raise [Errno::EACCES] If source file isn't readable
      def initialize(source_path, options = {})
        @source_path  = source_path
        @source       = File.read(source_path)
        @lines        = @source.lines.map(&:chomp)
        @prism_result = Prism.parse(@source)
        @parsed_at    = Time.now
        @options      = options
        @warnings     = []
      end

      # Parse the source file into structured test data
      #
      # @abstract Subclasses must implement this method
      # @return [Tryouts::Testrun] Parsed test structure with setup, tests, teardown, and warnings
      # @raise [NotImplementedError] If called directly on BaseParser
      def parse
        raise NotImplementedError, "Subclasses must implement #parse"
      end

      protected

      # Get the parser type identifier
      #
      # @abstract Subclasses should override to provide unique identifier
      # @return [Symbol] Parser type identifier
      def parser_type
        :base
      end

      # Access to instance variables for subclasses
      attr_reader :source_path, :source, :lines, :prism_result, :parsed_at, :options

    end
  end
end
