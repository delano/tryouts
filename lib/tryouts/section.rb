# lib/tryouts/section.rb

class Tryouts
  class Section < Array
    attr_accessor :path, :first, :last

    def initialize(path, start = 0)
      @path  = path
      @first = start
      @last  = start
    end

    def range
      @first..@last
    end

    def inspect
      range.to_a.zip(self).collect do |line|
        "%-4d %s\n" % line
      end.join
    end

    def to_s
      join($/)
    end
  end
end
