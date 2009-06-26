

group "Benchmarks"

tryouts "Benchmark Syntax", :benchmark do
  
  drill "can check the mean is <=", :mean, 4 do
    sleep 0.1 
  end
  
  drill "can check the standard deviation", :sdev, 0.1 do
    sleep 0.1
  end
  
  drill "Tryouts::Stat objects have a default name", :name, :unknown do
    sleep 0.1
  end
  
  dream :samples, 5
  drill "default repetitions is 5" do
    sleep 0.1
  end
  
  dream :proc, lambda { |x| x.sum >= 0.5 }
  drill "can specify dream proc" do
    sleep 0.1
  end
end
