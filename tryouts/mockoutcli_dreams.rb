
dreams "Common Usage" do
  dream "No args" do
    output inline(%Q{
         Date:                                   2009-02-16
       Owners:            greg, rupaul, telly, prince kinko
      Players:            d-bam, alberta, birds, condor man
    })
  end
  dream "YAML Output" do
    format :yaml
    output ({
      "Date" => "2009-02-16",
      "Players" => ["d-bam", "alberta", "birds", "condor man"],
      "Owners" => ["greg", "rupaul", "telly", "prince kinko"]
    })
  end
end

