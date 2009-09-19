

group "Benchmarks"

tryouts "Benchmark Syntax", :benchmark do
  
  drill "can check the mean is <=" do
    sleep 0.1 
  end
  
  drill "can check the standard deviation"  do
    sleep 0.1
  end
  
  drill "Tryouts::Stat objects have a default name" do
    sleep 0.1
  end
  
  drill "default repetitions is 5" do
    sleep 0.1
  end
  
  dream :proc, lambda { |x| x[:real].sum >= 0.5 }
  drill "can specify dream proc" do
    sleep 0.1
  end
end
