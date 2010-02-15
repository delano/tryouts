# See: http://yard.soen.ca/parser_arch.html
require 'yard'
include YARD::Parser::Ruby::Legacy
sample = DATA.read
statements = StatementList.new(sample)

lines = []
def parse (token, st, expct)
  if RubyToken::TkBlockContents === token
    llines, lexpct = [], []
    st.block.each do |t|
      parse t, st, lexpct
    end
    p [:tests, lexpct]
  elsif RubyToken::TkCOMMENT === token
    expct << token.text 
  else
    print "#{token.text}"
  end
end

statements.each do |st|  # YARD::Parser::Ruby::Legacy::Statement
  expct = []
  st.tokens.each_with_index do |token, index|
    parse token, st, expct
  end
  puts
end

#a.each do |st|
#  src = st.tokens.map do |token|
#    YARD::Parser::Ruby::Legacy::RubyToken::TkBlockContents === token ? st.block.to_s : token.text
#    p [:a, s]
#    s
#  end.join
#  puts src
#end
#
#b = YARD::Parser::Ruby::Legacy::RubyLex.new(sample)
#p b.methods.sort
#p YARD::Parser::SourceParser.parse_string(sample)

__END__
1 + 1
class Test
 def test_foo
   1 + 1 if true
   #=> 2
   #=> <Fixnum>
 end
end