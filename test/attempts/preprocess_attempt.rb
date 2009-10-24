# Usage ruby test/preprocess_attempt.rb
module Tryouts
  class << self
    def preprocess(str)
      lines = str.split $/
      out = []
      lines.each_with_index do |l,i|
        out.push(l) and next unless l.match /\# *=> *(.+)/
        out[-1] = "ret = " << out[-1]
        out << "Tryouts.assert_equal(ret, #{$1})"
      end
      out
    end
  end
end

puts Tryouts.preprocess(DATA.read).join $/


__END__
# test expectation type matters
foo = 1 + 1
@bar = 2 + 2
foo
#=> 2
