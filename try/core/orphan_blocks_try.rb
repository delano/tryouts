# try/core/orphan_blocks_try.rb
#
# frozen_string_literal: true

# Code with no description and no expectations between test cases (an orphan
# block) executes in source order instead of being silently dropped. Its side
# effects - instance variables AND local variables - are visible to later
# tests, because shared-context mode evaluates every block against one
# reused Binding.

## TEST: test before the orphan block
@before_orphan = "ran"
@before_orphan
#=> "ran"

@orphan_ivar = "set by orphan"

# The comment and blank lines in this block are deliberate: extracted code
# keeps them as padding so the statements below stay on their real lines.

orphan_local = 42

## TEST: orphan side effects are visible in later tests
[@orphan_ivar, orphan_local]
#=> ["set by orphan", 42]

## TEST: a block is anchored at its first executable line, not at its start
# line_range opens at the description or leading comment, so it is the wrong
# line to hand to eval. first_code_line points at the first statement instead.
@parsed = Tryouts::EnhancedParser.new(__FILE__).parse
@case   = @parsed.test_cases.find { |tc| tc.is_a?(Tryouts::TestCase) }
File.readlines(__FILE__)[@case.eval_start_line - 1].strip
#=> '@before_orphan = "ran"'

## TEST: every executable line in a multi-line block reports its true source line
# Joining only the code lines would collapse the gaps above and report each
# later statement several lines early, so a backtrace would point at the wrong
# code. Anything listed here is a statement whose reported line is a lie.
@source = File.readlines(__FILE__).map(&:chomp)
@orphan = @parsed.test_cases.find { |tc| tc.is_a?(Tryouts::OrphanBlock) }
@orphan.code.lines.each_with_index.filter_map do |line, offset|
  next if line.strip.empty?

  line.chomp unless @source[@orphan.eval_start_line + offset - 1] == line.chomp
end
#=> []

## TEST: the padding spans the block, so the last statement lands on its own line
@source[@orphan.eval_start_line + @orphan.code.lines.count - 2]
#=> 'orphan_local = 42'
