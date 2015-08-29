# == Class: rsyslog::service
#
# Ensure the RSyslog daemon stays running.
#
class rsyslog::service {
  assert_private()

  service { 'rsyslog':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true
  }
}
