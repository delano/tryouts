
class Tryouts::Tryout
  
    # The name of this tryout
  attr_reader :name
  
    # An Array of Drill objects
  attr_reader :drills
    # An Array of Drill results
  attr_reader :results
  
    # A default value for Drill.dtype
  @@default_dtype = :cli
  @@valid_dtypes = [:cli]
  
  def initialize(name, dtype)
    if !dtype.nil? && !@@valid_dtypes.member?( dtype)
      abort "#{dtype} is not a valid drill type"
    end
    @name = name
    @@default_dtype = dtype unless dtype.nil?
    @drills = []
    @results = []
  end
  
  ## ---------------------------------------  EXTERNAL API  -----
  def from_block(b, &inline)
    instance_eval &b
  end
  
  def run
    drills.each do |drill|
      print Tryouts::TRYOUT_MSG % @name
      response = drill.run
      puts drill.success?
      @results << response
    end
    
  end
  
  # Did every Tryout finish successfully?
  def success?
    # Returns true only when every Tryout result returns true
    !(@results.collect { |r| r.success? }.member?(false))
  end
  
    
  def add_drill(d)
    drills << d
  end
  
  def drill(*args, &b)
    drill = Tryouts::Drill.new(@@default_dtype, *args, &b)
    add_drill drill
  end
end