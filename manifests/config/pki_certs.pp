# == Class: rsyslog::pki
#
# Ensures that SIMP copies PKI certificates readable by the rsyslog user into
# /etc/rsyslog.d/pki
#
#
class rsyslog::config::pki_certs {
  assert_private()

  include 'pki'
  ::pki::copy { $::rsyslog::cert_source:
    owner  => 'root',
    group  => 'root',
  }
}
