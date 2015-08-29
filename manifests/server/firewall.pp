# == Class: rsyslog::server::firewall
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
class rsyslog::server::firewall {
  include '::rsyslog'
  include '::rsyslog::server'
  assert_private()

  if $::rsyslog::tls_tcp_server {
    iptables::add_tcp_stateful_listen { 'syslog_tls_tcp':
      client_nets => $::rsyslog::client_nets,
      dports      => $::rsyslog::tls_listen_port
    }
  }

  if $::rsyslog::tcp_server {
    iptables::add_tcp_stateful_listen { 'syslog_tcp':
      client_nets => $::rsyslog::client_nets,
      dports      => $::rsyslog::tcp_listen_port
    }
  }

  if $::rsyslog::udp_server {
    iptables::add_udp_listen { 'syslog_udp':
      client_nets => $::rsyslog::client_nets,
      dports      => $::rsyslog::udp_listen_port
    }
  }
}
