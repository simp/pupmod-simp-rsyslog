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
          # Have to check for empty stripped $2 because regex will actually
          # match a value string that has multiple whitespace characters.
          # In that case $2 will contain a single whitespace character.
          if $1 && $2 && !$2.strip.empty?
            key = $1.strip
            value = $2.strip

            if value =~ /^yes$/i
              value = true
            elsif value =~ /^no$/i
              value = false
            elsif (value =~ /^\d+$/)
              value = value.to_i
            end

            response['features'][key] = value
          end
        end
      end
    end

    response
  end
end
