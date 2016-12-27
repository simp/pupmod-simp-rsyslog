# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Sets up TCPWrappers for RSyslog both plain TCP and TCP over TLS as necessary
#
# **NOTE:** This actually **opens** the TCPWrappers rules for RSyslog since
# testing has shown that it was prone to some odd connectivity errors. Both
# IPTables and an internal allow list protect RSyslog connections.
#
class rsyslog::server::tcpwrappers {
  assert_private()

  include '::tcpwrappers'

  if $::rsyslog::tcp_server {
    tcpwrappers::allow { 'syslog':
      pattern => 'ALL'
    }
  }

  if $::rsyslog::tls_tcp_server {
    tcpwrappers::allow { 'syslog_tls':
      pattern => 'ALL'
    }
  }
}
