# == Class: rsyslog::server::selinux
#
# Sets up SELinux for RSyslog.
#
class rsyslog::server::selinux {
  assert_private()

  if ($::operatingsystem in ['RedHat','CentOS']) and ("${::operatingsystemmajrelease}" > '6') {
    if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
      # nis_enabled must be turned on for socket connections.
      selboolean { 'nis_enabled':
        persistent => true,
        value      => 'on'
      }
    }
  }
}
