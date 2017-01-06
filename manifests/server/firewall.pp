# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Sets up the firewall rules for RSyslog with IPTables
#
# In ports will be openened for all systems inside of the
# ``$::rsyslog::trusted_nets`` Array.
#
class rsyslog::server::firewall {
  assert_private()

  if $::rsyslog::tls_tcp_server {
    iptables::listen::tcp_stateful { 'syslog_tls_tcp':
      trusted_nets => $::rsyslog::trusted_nets,
      dports       => $::rsyslog::tls_tcp_listen_port
    }
  }

  if $::rsyslog::tcp_server {
    iptables::listen::tcp_stateful { 'syslog_tcp':
      trusted_nets => $::rsyslog::trusted_nets,
      dports       => $::rsyslog::tcp_listen_port
    }
  }

  if $::rsyslog::udp_server {
    iptables::listen::udp { 'syslog_udp':
      trusted_nets => $::rsyslog::trusted_nets,
      dports       => $::rsyslog::udp_listen_port
    }
  }
}
