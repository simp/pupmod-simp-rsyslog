# == Class: rsyslog::server::selinux
#
# Sets up SELinux for RSyslog.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class rsyslog::server::selinux {
  if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
    # nis_enabled must be turned on for socket connections.
    selboolean { 'nis_enabled':
      persistent => true,
      value      => 'on'
    }
  }
}
