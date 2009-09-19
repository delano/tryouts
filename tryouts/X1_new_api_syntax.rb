## Tryouts 0.8

library :rudy, 'path/2/rudy/lib'
tryouts "Code", :api do
  dream :class, Rudy::Disk
  dream :size, 1
  dream :device, '/dev/sdh'
  dream :path, '/'
  drill "has a default size and device" do
    Rudy::Disk.new('/')
  end

  drill "save disk metadata", true do
    Rudy::Disk.new('/any/path').save
  end

  dream :exception, Rudy::Metadata::DuplicateRecord
  drill "won't save over a disk with the same name" do
    Rudy::Disk.new('/any/path').save
  end

  set :group_name, "grp-9000"
  dream :class, Rudy::AWS::EC2::Group
  dream :proc, lambda { |group|
    accountnum = Rudy::Huxtable.config.accounts.aws.accountnum
    should_have = "#{accountnum}:#{group_name}"
    return false unless group.groups.is_a?(Hash)
    group.groups.has_key?(should_have) == true
  }
  drill "group (#{group_name}) contains new rules" do
    stash :group, Rudy::AWS::EC2::Groups.get(group_name)
  end
end






## Comment-style
library :rudy, 'path/2/rudy/lib'
tryouts "API", :api do

  # "has a default size and device"
  Rudy::Disk.new '/'                              # <Rudy::Disk>
                                                  # obj.size == 1
                                                  # obj.device == '/dev/sdh'
                                                  # obj.path == '/'
                                                
  # "save disk metadata"                          
  Rudy::Disk.new('/any/path').save                # true
                                                    
  # "won't save over a disk with the same name"
  Rudy::Disk.new('/any/path').save                # ! <Rudy::Metadata::DuplicateRecord>
                                                    
  # "group contains new rules"
  group_name = "grp-9000"
  accountnum = Rudy::Huxtable.config.accounts.aws.accountnum
  Rudy::AWS::EC2::Groups.get(group_name)          # <Rudy::AWS::EC2::Group>
                                                  # obj.groups.has_key?("#{accountnum}:#{group_name}")
end


