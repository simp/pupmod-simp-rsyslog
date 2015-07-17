# == Class: rsyslog::firewall
#
# Sets up the SIMP firewall rules for RSyslog with IPTables.
#
# If the tcpserver variable is set to true, IPTables will allow connections
# on port 514. If the tls_tcpserver variable is set to true, IPTables will allow
# connections on port 6514.
#
# In both of these instances, these ports will be open for all systems inside of the
# $client_nets array, which is defined globally as a list of subnets.
#
# == Parameters
#
# [*tcpserver*]
#  Type: Boolean
#  Default: $::rsyslog::params::tcpserver
#
#  Whether or not to setup a listening TCP Server for RSyslog on this host.
#
# [*tcpServerRun*]
#  Type: Port
#  Default: $::rsyslog::params::tcpServerRun
#
#  The port to establish connections on for the RSyslog TCP Server.
#
# [*tls_tcpserver*]
#  Type: Boolean
#  Default: $::params::tls_tcpserver
#
#   Whether or not to setup a listening TLS TCP Server for RSyslog on this host.
#
# [*tls_tcpServerRun*]
#  Type: Port
#  Default: $::rsyslog::params::tls_tcpServerRun
#
#  The port to establish connections for the RSyslog TLS TCP Server.
#
# [*udpserver*]
#  Type: Boolean
#  Default: $::rsyslog::params::udpserver
#  
#  Whether or not to setup a listening UDP Server for RSyslog on this host.
#
# [*udpServerRun*]
#  Type: Port
#  Default: $::rsyslog::params::udpServerRun
#
#  The port to establish connection for the RSyslog UDP Server.
#
# == Authors
#
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class rsyslog::firewall(
  $tcpserver        = $::rsyslog::params::tcpserver,
  $tcpServerRun     = $::rsyslog::params::tcpServerRun,
  $tls_tcpserver    = $::rsyslog::params::tls_tcpserver,
  $tls_tcpServerRun = $::rsyslog::params::tls_tcpServerRun,
  $udpserver        = $::rsyslog::params::udpserver,
  $udpServerRun     = $::rsyslog::params::udpServerRun,
  $client_nets      = $::rsyslog::params::client_nets
) inherits rsyslog::params {

  validate_bool($tcpserver)
  validate_bool($tls_tcpserver)
  validate_bool($udpserver)
  validate_net_list($client_nets)
  validate_port($tcpServerRun)
  validate_port($tls_tcpServerRun)
  validate_port($udpServerRun)

  if $tls_tcpserver {
    iptables::add_tcp_stateful_listen { 'syslog_tls_tcp':
      client_nets => $client_nets,
      dports      => $tls_tcpServerRun
    }
  }

  if $tcpserver {
    iptables::add_tcp_stateful_listen { 'syslog_tcp':
      client_nets => $client_nets,
      dports      => $tcpServerRun
    }
  }

  if $udpserver {
    iptables::add_udp_listen { 'syslog_udp':
      client_nets => $client_nets,
      dports      => $udpServerRun
    }
  }
}
