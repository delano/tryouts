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
orphan_local = 42

## TEST: orphan side effects are visible in later tests
[@orphan_ivar, orphan_local]
#=> ["set by orphan", 42]

## TEST: an orphan block's line_range points at its first source line
# `line_range.first` is 0-based, so executors and translators add 1 to get the
# 1-based line they hand to eval - that offset is what makes a raise inside an
# orphan block report the real source location instead of line 1.
@orphan = Tryouts::EnhancedParser.new(__FILE__).parse.test_cases.find { |tc| tc.is_a?(Tryouts::OrphanBlock) }
File.readlines(__FILE__)[@orphan.line_range.first].strip
#=> @orphan.code.lines.first.strip
#=> '@orphan_ivar = "set by orphan"'
