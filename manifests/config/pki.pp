# == Class: rsyslog::pki
#
# Ensures that there are PKI certificates readable by the rsyslog user in
# /etc/rsyslog.d/pki
#
# == Parameters
#
# [*sert_source*]
#  Type: Absolute Path/String
#  Default: ''
#
#  The source of the system PKI certificates to copy into /etc/rsyslog.d/pki
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
#
class rsyslog::config::pki (
  $cert_source = ''
) {
  if !empty($cert_source) { validate_absolute_path($cert_source) }

  if empty($cert_source) {
    include 'pki'

    ::pki::copy { '/etc/rsyslog.d': }
  }
  else {
    file { '/etc/rsyslog.d/pki':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
      source => $cert_source
    }
  }
}
