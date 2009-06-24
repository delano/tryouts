
TRYOUTS_HOME = File.expand_path(File.join(File.dirname(__FILE__), ".."))
MOCKOUT_PATH = File.join(TRYOUTS_HOME, "bin", "mockout")

##group "mockout cli"
##command :mockout, MOCKOUT_PATH
##dreams File.join(GYMNASIUM_HOME, 'mockoutcli_dreams.rb')
##
##tryout "Common Usage" do
##  drill     "No args",            :info
##  drill "YAML Output", :f, :yaml, :info
##  drill "JSON Output", :f, :json, :info
##end
##
##tryout "inline dream that passes", :cli, :mockout do
##  output = ["we expect mockout to", "echo these lines back"]
##
##  # $ bin/mockout sergeant -e "we expect mockout to" "echo these lines back"
##  drill "echo arguments", :info, :e, output[0], output[1]
##  dream "echo arguments", output
##end
##
##tryout "inline dream that fails", :cli, :mockout do
##  dream "echo arguments", "The dream does"
##  drill "echo arguments", :info, :e, "not match reality"
##end
##
##
##dreams "Common Usage" do
##  dream "No Comman" do
##    output inline(%Q{
##    Date:                                   2009-02-16
##  Owners:            greg, rupaul, telly, prince kinko
## Players:            d-bam, alberta, birds, condor man
##    })
##  end
##  dream "YAML Output" do
##    format :to_yaml
##    output ({
##      "Date" => "2009-02-16",
##      "Players" => ["d-bam", "alberta", "birds", "condor man"],
##      "Owners" => ["greg", "rupaul", "telly", "prince kinko"]
##    })
##  end
##end

