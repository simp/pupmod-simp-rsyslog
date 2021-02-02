# @summary Sets up SELinux for RSyslog
#
# Switches on the ``nis_enabled`` SELinux Boolean since this is required for
# successful RSyslog connections.
#
# @note This **MAY** not be necessary any longer and should be validated
# @api private
#
class rsyslog::server::selinux {
  assert_private()

  if $facts['selinux_current_mode'] and $facts['selinux_current_mode'] != 'disabled' {
    selboolean { 'nis_enabled':
      persistent => true,
      value      => 'on'
    }
  }
}
