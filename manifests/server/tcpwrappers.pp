# @summary Sets up TCPWrappers for RSyslog both plain TCP and TCP over TLS as necessary
#
# **NOTE:** This actually **opens** the TCPWrappers rules for RSyslog since
# testing has shown that it was prone to some odd connectivity errors. Both
# the host firewall and an internal allow list protect RSyslog connections.
#
# @api private
#
class rsyslog::server::tcpwrappers {
  assert_private()

  simplib::assert_optional_dependency($module_name, 'simp/tcpwrappers')

  include 'tcpwrappers'

  if $rsyslog::tcp_server {
    tcpwrappers::allow { 'syslog':
      pattern => 'ALL'
    }
  }

  if $rsyslog::tls_tcp_server {
    tcpwrappers::allow { 'syslog_tls':
      pattern => 'ALL'
    }
  }
}
