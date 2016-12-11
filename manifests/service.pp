# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Manage the RSyslog service
#
# @param enable
#   Enable the rsyslog service
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

  service { $::rsyslog::service_name:
    ensure     => $_ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true
  }
}
