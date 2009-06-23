
class Tryouts
  class Tryout
    
    # All :api Drills are run within this context (not used for :cli). 
    # Each Drill is executed in a new instance of this class. That means
    # instance variables are not carried through, but class variables are. 
    # The before and after blocks are also run in this context.
    class DrillContext
        # An ordered Hash of stashed objects. 
      attr_writer :stash
        # A value used as the dream output that will overwrite a predefined dream
      attr_writer :dream
      attr_writer :format
      attr_writer :rcode
      attr_writer :emsg
      attr_writer :output

      def initialize; @stash = Tryouts::HASH_TYPE.new; @has_dream = false; end

      # Set to to true by DrillContext#dream
      def has_dream?; @has_dream; end

      # If called with no arguments, returns +@stash+. 
      # If called with arguments, it will add a new value to the +@stash+
      # and return the new value.  e.g.
      #
      #     stash :name, 'some value'   # => 'some value'
      #
      def stash(*args)
        return @stash if args.empty?
        @stash[args[0]] = args[1] 
        args[1] 
      end
      
    end
  end
end