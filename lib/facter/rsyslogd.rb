# _Description_
#
# Returns information about the installed rsyslog version
#
Facter.add('rsyslogd') do
  rsyslogd = Facter::Core::Execution.which('rsyslogd')
  confine { rsyslogd }

  setcode do
    rsyslogd_info = Facter::Core::Execution.exec("#{rsyslogd} -v").strip.lines

    response = {
      'version'  => nil,
      'features' => {},
    }

    version_line = rsyslogd_info.shift

    if version_line =~ %r{rsyslogd\s+(\d+\.\d+\.\d+)}
      response['version'] = Regexp.last_match(1)

      rsyslogd_info.each do |info_line|
        next unless info_line =~ %r{\s+(.+):\s+(.+)$}
        # Have to check for empty stripped $2 because regex will actually
        # match a value string that has multiple whitespace characters.
        # In that case $2 will contain a single whitespace character.
        next unless Regexp.last_match(1) && Regexp.last_match(2) && !Regexp.last_match(2).strip.empty?
        key = Regexp.last_match(1).strip
        value = Regexp.last_match(2).strip

        if %r{^yes$}i.match?(value)
          value = true
        elsif %r{^no$}i.match?(value)
          value = false
        elsif %r{^\d+$}.match?(value)
          value = value.to_i
        end

        response['features'][key] = value
      end
    end

    response
  end
end
