
library :tryouts, File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

group "Mixins"

test_hash = { :level1 => { :level2 => {} } }

tryouts "Hash" do
  
  drill "knows the deepest point", test_hash, 3, :deepest_point
  drill "has a last method", {}, :last, :respond_to?
  
  drill "1", 2, 3, :gte
  
  dream :githash2, :respond_to?
  dream '896cac2add25d7ad59256032d76568cdf93415eb2', :githash
  drill "can calculate a SHA1 hash", test_hash
end