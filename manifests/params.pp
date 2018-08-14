# A list of the parameters and their default values for Rsyslog.
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
# @param rsyslog7 [Boolean]
#   Whether Rsyslog 7 is being used.  This older version requires different
#   configuration for ``TLS`` that the latest EL version.
#
# @author https://github.com/simp/pupmod-simp-rsyslog/graphs/contributors
#
class rsyslog::params {
  $service_name       = 'rsyslog'
  if ($facts['os']['name'] in ['RedHat','CentOS','OracleLinux']) and ($facts['os']['release']['major'] == '6') {
    $package_name  = 'rsyslog7'
    $read_journald = false
    $rsyslog7      = true
  }
  else {
    $package_name  = 'rsyslog'
    $read_journald = true
    $rsyslog7      = false
  }

  $tls_package_name = "${package_name}-gnutls"
}
