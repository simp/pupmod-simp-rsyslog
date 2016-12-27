# A list of the parameters and their default values for RSyslog.
#
# @param service_name [String]
#   The name of the rsyslog service
#
# @param package_name [String]
#   The name of the rsyslog package
#
# @param tls_package_name [String]
#   The name of the rsyslog package providing GNUTLS support
#
# @param read_journald [Boolean]
#   Tie in the reading of ``journald`` if available
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsyslog::params {
  $service_name       = 'rsyslog'
  if ($facts['os']['name'] in ['RedHat','CentOS']) and ($facts['os']['release']['major'] == '6') {
    $package_name  = 'rsyslog7'
    $read_journald = false
  }
  else {
    $package_name  = 'rsyslog'
    $read_journald = true
  }

  $tls_package_name = "${package_name}-gnutls"
}
