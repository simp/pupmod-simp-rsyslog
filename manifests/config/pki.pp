# == Class: rsyslog::pki
#
# Ensures that there are PKI certificates readable by the rsyslog user in
# /etc/rsyslog.d/pki
#
# == Parameters
#
# [*cert_source*]
#   Type: Absolute Path
#   Default: ''
#     If _$use_simp_pki_ is false, then pull all certificates from
#     this valid Puppet File resource source. They should be in the
#     same format as expected from the SIMP PKI structure.
#     Example Layout:
#       private/<fqdn>.pem
#       public/<fqdn>.pub
#       cacerts/cacerts.pem <- All CA certificates go here!
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
