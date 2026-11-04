# lib/tryouts/translators/eval_source.rb
#
# frozen_string_literal: true

class Tryouts
  module Translators
    # Direct mode evaluates each section with the file's leading magic
    # comments (such as "# frozen_string_literal: true") on the lines above
    # it. The translators evaluate the same way, so a test sees the same
    # literals under --rspec and --minitest.
    #
    # Each method returns the arguments for instance_eval, class_eval or
    # eval: the code under the magic comments, the file's path, and a first
    # line that keeps the code on its own line in the file.
    module EvalSource
      # A setup, test case, interlude or teardown
      def self.section(testrun, section)
        build(testrun, section.code, section.eval_start_line)
      end

      # An expectation's expression, on the expectation's line. Hand-built
      # expectations may have no line.
      def self.expectation(testrun, expectation)
        build(testrun, expectation.content, expectation.line ? expectation.line + 1 : 1)
      end

      def self.build(testrun, code, line)
        magic = testrun.magic_comments
        [[*magic, code].join("\n"), testrun.source_file, line - magic.size]
      end
      private_class_method :build
    end
  end
end
