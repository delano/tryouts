## Tryouts 0.8

command :script, '/path/2/script'

tryouts "CLI", :cli do
  dream :grep, /UTC/
  drill "can display date", :date
  
  dream []
  drill "can be quiet", :q, :test
  
  dream :match, /\d+\.\d+\.\d+\.\d+/
  drill "can execute a block of commands" do
    ret = rudy :q, :myaddress, :e
    ret.first
  end
end

## Comment-style

command :script, '/path/2/script'
tryouts "CLI", :cli do
  
  # "can display date"
  script :date                                    # stdout.grep /UTC/
                                                  # stderr.empty? == true

  # "can be quiet"
  script :q, :test                                # stdout.empty? == true
  
  # "can execute a block of commands"
  ls :a, '/tmp'
  script :q, :myaddress, :e                       # stdout.first.match /\d+\.\d+\.\d+\.\d+/
  
end

