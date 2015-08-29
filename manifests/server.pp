# == Class: rsyslog::server
#
# Sets up the RSyslog server.
#
# == Parameters
#
# [*tcp_server*]
# Type: Boolean
# Default: $::rsyslog::params::tcp_server
#   A flag to toggle whether this instance will be a TCP Rsyslog server.
#
# [*tcp_listen_port*]
# Type: Port/String
# Default: $::rsyslog::params::tcp_listen_port
#   If this instance is a TCP RSyslog server, this will be the port to listen for incoming
#   connections on. This can be set if tcp_server is false, but will be ignored.
#
# [*tls_tcp_server*]
# Type: Boolean
# Default: $::rsyslog::params::tls_tcp_server
#   A flag to toggle whether this instance is a TLS TCP RSyslog server. If enabled, this log
#   server will expect all logs to be encrypted on the given TLS port (see tls_listen_port).
#
# [*tls_listen_port*]
# Type: Port/String
# Default: $::rsyslog::params::tls_listen_port
#   If this instance is a TLS TCP RSyslog server, this will be the port to listen for
#   incoming connections on. This can be set if tls_tcp_server is false, but will be ignored.
#
# [*udp_server*]
# Type: Boolean
# $::rsyslog::params::udp_server
#   A flag to toggle whether this instance will be a UDP RSyslog server.
#
# [*udp_server_address*]
#
# [*udp_listen_port*]
# Type: Port/String
# Default: $::rsyslog::params::udp_listen_port
#   If this instance is a UDP RSyslog server, this will be the port to listen for incoming
#   connections on. This can be set if udp_server is false, but will be ignored.
#
# [*manage_firewall*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages firewall rules to accomodate RSyslog.
#
# [*manage_selinux*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages SELinux rules for RSyslog.
#
# [*manage_tcpwrappers*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages the TCPWrappers configuration for RSyslog.
#
class rsyslog::server (
  $manage_firewall       = defined('$::use_iptables') ? { true => $::use_iptables, default => hiera('use_iptables',true) },
  $manage_selinux = defined('$::manage_selinux') ? { true => $::manage_selinux, default => hiera('manage_selinux',true) },
  $manage_tcpwrappers    = defined('$::manage_tcpwrappers') ? { true => $::manage_tcpwrappers, default => hiera('manage_tcpwrappers',true) }
) {
  validate_bool($manage_firewall)
  validate_bool($manage_selinux)
  validate_bool($manage_tcpwrappers)

  include '::rsyslog'

  if $manage_firewall {
    include '::rsyslog::server::firewall'
    Class['rsyslog::server::firewall'] ->
    Class['rsyslog::service']
  }

  if $manage_selinux {
    include '::rsyslog::server::selinux'
    Class['rsyslog::server::selinux'] ->
    Class['rsyslog::service']
  }

  if $manage_tcpwrappers {
    include '::rsyslog::server::tcpwrappers'
    Class['rsyslog::server::tcpwrappers'] ->
    Class['rsyslog::service']
  }
}
