
class Hash
  
  # A depth-first look to find the deepest point in the Hash. 
  # The top level Hash is counted in the total so the final
  # number is the depth of its children + 1. An example:
  # 
  #     ahash = { :level1 => { :level2 => {} } }
  #     ahash.deepest_point  # => 3
  #
  def deepest_point(h=self, steps=0)
    if h.is_a?(Hash)
      steps += 1
      h.each_pair do |n,possible_h|
        ret = deepest_point(possible_h, steps)
        steps = ret if steps < ret
      end
    else
      return 0
    end
    steps
  end
  
  unless method_defined?(:last)
    # Ruby 1.9 doesn't have a Hash#last (but Tryouts::OrderedHash does). 
    # It's used in Tryouts to return the most recently added instance of
    # Tryouts to @@instances. 
    #
    # NOTE: This method is defined only when Hash.method_defined?(:last)
    # returns false. 
    def last
      self[ self.keys.last ]
    end
  end
  
  
  def gitash(s)
    # http://stackoverflow.com/questions/552659/assigning-git-sha1s-without-git
    # http://github.com/mojombo/grit/blob/master/lib/grit/git-ruby/git_object.rb#L81
    # http://github.com/mojombo/grit/blob/master/lib/grit/git-ruby/git_object.rb#L225
    # http://www.kernel.org/pub/software/scm/git-core/docs/git-hash-object.html
    # $ git hash-object file
    DIGEST_TYPE.hexdigest(("%s %d\0" % ['blob', s.length]) << s)
  end
end

