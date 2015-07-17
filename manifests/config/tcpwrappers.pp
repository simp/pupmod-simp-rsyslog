# == Class: rsyslog::tcpwrappers
#
# Sets up TCPWrappers for RSyslog both plain TCP and over TLS as necessary.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class rsyslog::config::tcpwrappers {
  include '::rsyslog'
  include '::tcpwrappers'

  # This is blocked two other places, adding this to tcpwrappers is a bit
  # overkill and prone to strange errors.
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
