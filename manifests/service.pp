# == Class: rsyslog::service
#
# Ensure the RSyslog daemon stays running.
#
# == Authors
#
# * Mike Riddle <mriddle@onyxpoint.com>
# * Kendall Moore <kmoore@keywcorp.com>
#
class rsyslog::service {
  service { 'rsyslog':
    ensure     => 'running',
    enable     => true,
    binary     => '/usr/bin/rsyslog',
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File['/etc/rsyslog.conf'],
      Package["rsyslog.$::hardwaremodel"]
    ]
  }
}
