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
    # section returns the arguments for instance_eval, class_eval or eval:
    # the code under the magic comments, the file's path, and a first line
    # that keeps the code on its own line in the file. Expectations go
    # through the evaluators, whose EvaluationContext does the same.
    module EvalSource
      # A setup, test case, interlude or teardown
      def self.section(testrun, section)
        magic = testrun.magic_comments
        [[*magic, section.code].join("\n"), testrun.source_file, section.eval_start_line - magic.size]
      end
    end
  end
end
