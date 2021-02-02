# _Description_
#
# Returns information about the installed rsyslog version
#
Facter.add("rsyslogd") do
  rsyslogd = Facter::Core::Execution.which('rsyslogd')
  confine { rsyslogd }

  setcode do
    rsyslogd_info = Facter::Core::Execution.exec("#{rsyslogd} -v").strip.lines

    response = {
      'version'  => nil,
      'features' => {}
    }

    version_line = rsyslogd_info.shift

    if version_line =~ /rsyslogd\s+(\d+\.\d+\.\d+)/
      response['version'] = $1

      rsyslogd_info.each do |info_line|
        if info_line =~ /\s+(.+):\s+(.+)$/
          if $1 && $2
            key = $1.strip
            value = $2.strip

            value = (value == 'Yes' ? true : false)
            value = value.to_i if (value =~ /^\d+$/)

            response['features'][key] = value
          end
        end
      end
    end

    response
  end
end
