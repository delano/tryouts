# FAILED
require 'pp'
file = DATA.read.strip
blocks = file.scan(/\n*(((?!#=>).)+\n?#=> *([^\n]+)\n+)+/m)

p blocks.size
blocks.each do |b|
  puts '----------------'
  puts b.first
end
__END__
# test1
'foo' + 'bar'
#=> 'foobar'

# test2
'foo'.class
#=> String