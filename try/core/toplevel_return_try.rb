# try/core/toplevel_return_try.rb
#
# frozen_string_literal: true

# A top-level `return` in test code has no live frame to jump to (each block
# is evaluated against a long-lived Binding whose home frame is already dead),
# so it raises LocalJumpError as a normal per-test error. Previously it
# triggered a non-local return that silently corrupted the results array.

## TEST: top-level return raises LocalJumpError instead of corrupting results
return 5
#=!> error.is_a?(LocalJumpError)

## TEST: the batch continues normally after the LocalJumpError
1 + 1
#=> 2
