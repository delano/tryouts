
dreams 'common usage' do
  dream 'no args' do
    output inline(%Q{
          Date:                                   2009-02-16
       Players:            d-bam, alberta, birds, condor man
       Coaches:               greg|rupaul|telly|prince kinko
    })
  end
  dream 'yaml output' do
    rcode 0
    format :yaml
    output inline(%Q{
          Date:                                   2009-02-16
       Players:            d-bam, alberta, birds, condor man
       Coaches:               greg|rupaul|telly|prince kinko
    })
  end
end

