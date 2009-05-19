require 'rubygems'
require 'rye'
require 'yaml'

module Rye::Cmd
  def rudy(*args); cmd(:rudy, *args); end
end

rbox = Rye::Box.new
res1 = rbox.rudy
res2 = YAML.load(res1.to_yaml)
p res1 == res2
p res2