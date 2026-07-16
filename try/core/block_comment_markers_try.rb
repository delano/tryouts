# try/core/block_comment_markers_try.rb
#
# frozen_string_literal: true

# Marker-shaped lines that are not real expectations: inside a =begin/=end
# block comment (a single multi-line Prism comment node) and inside an
# unclosed multi-line array literal. Both were previously misparsed - the
# block comment crashed the parser, the array comment split the test block.

## TEST: test before a block comment parses normally
1 + 1
#=> 2

=begin
This is a block comment.
#=> this looks like an expectation but is inside =begin/=end
x = 99
=end

## TEST: test after the block comment still parses
2 + 2
#=> 4

## TEST: marker-shaped comment inside a multi-line array literal stays a comment
result = [
  1,
  2,
#=> not a real expectation, just discussing indices
]
result
#=> [1, 2]
