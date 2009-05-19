
class Tryouts::Tryout
  
    # The name of this tryout
  attr_reader :name
  
    # An Array of Drill objects
  attr_reader :drills
  
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
  end
  
  ## ---------------------------------------  EXTERNAL API  -----
  def from_block(b, &inline)
    instance_eval &b
  end
  
  def run
    drills.each do |drill|
      begin
        drill.run
      rescue Interrupt
      end
    end
  end
  
  def add_drill(d)
    drills << d
  end
  
  def drill(rcode, *args, &b)
    drill = Tryouts::Drill.new(@@default_dtype, rcode, *args, &b)
    add_drill drill
  end
end