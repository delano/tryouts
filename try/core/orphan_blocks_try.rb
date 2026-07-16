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
