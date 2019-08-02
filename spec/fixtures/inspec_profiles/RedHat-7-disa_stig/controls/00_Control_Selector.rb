skips = {}
overrides = []
subsystems = [ 'rsyslog' ]


require_controls 'disa_stig-el7-baseline' do
  skips.each_pair do |ctrl, reason|
    control ctrl do
      describe "Skip #{ctrl}" do
        skip "Reason: #{skips[ctrl]}" do
        end
      end
    end
  end

  @conf['profile'].info[:controls].each do |ctrl|
    next if (overrides + skips.keys).include?(ctrl[:id])

    tags = ctrl[:tags]
    if tags && tags[:subsystems]
      subsystems.each do |subsystem|
        if tags[:subsystems].include?(subsystem)
          control ctrl[:id]
        end
      end
    end
  end

  ## Overrides ##

# # USEFUL DESCRIPTION
# control 'V-IDENTIFIER' do
#   # Enhancement, leave this out if you just want to add a different test
#   overrides << self.to_s
#
#   only_if { file('whatever').exist? }
# end
end
