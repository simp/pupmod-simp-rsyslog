# @summary Manage the RSyslog service
#
# @param enable
#   Enable the rsyslog service
#
# @api private
#
class rsyslog::service(
  Boolean $enable = true
){
  assert_private()

  if $enable {
    $_ensure = 'running'
  }
  else {
    $_ensure = 'stopped'
  }

  service { $rsyslog::service_name:
    ensure     => $_ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true
  }
}
