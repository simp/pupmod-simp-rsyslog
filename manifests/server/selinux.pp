# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Sets up SELinux for RSyslog
#
# Switches on the ``nis_enabled`` SELinux Boolean since this is required for
# successful RSyslog connections.
#
# @note This **MAY** not be necessary any longer and should be validated
#
class rsyslog::server::selinux {
  assert_private()

  if ($facts['os']['name'] in ['RedHat','CentOS','OracleLinux']) and ($facts['os']['release']['major'] > '6') {
    if $facts['selinux_current_mode'] and $facts['selinux_current_mode'] != 'disabled' {
      selboolean { 'nis_enabled':
        persistent => true,
        value      => 'on'
      }
    }
  }
}
