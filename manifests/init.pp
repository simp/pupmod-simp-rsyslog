# == Class: rsyslog
#
# Sets up RSyslog.
#
# It is assumed that local6 will be used for all logs collected from files.
#
# You will need to add a rule specifically for this if you want to send them to
# a remote host.
#
# == Parameters
#
# [*service_name*]
# Type: Strinig
# Default: $::rsyslog::params::service_name
#   The name of the RSyslog service. Typically 'rsyslog'
#
# [*package_name*]
# Type: String
# Default: $::rsyslog::params::package_name
#   The name of the package to install RSyslog. Typically 'rsyslog'
#
# [*tls_package_name*]
# Type: String
# Default: $::rsyslog::params::tls_package_name
#   The name of the package to install RSyslog TLS utilities. Typically 'rsyslog-gnutls'
#
# [*client_nets*]
# Type: Array of strings
# Default $::rsyslog::params::client_nets
#   A whitelist of subnets (in CIDR notation) permitted access. Most notably, this will
#   be used in conjunction with IPTables (if enabled) to allow connections from within
#   the given subnets.
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
# [*enable_tls*]
# Type: Boolean
# Default: $::rsyslog::params::enable_tls
#   A flag to toggle whether RSyslog should enable the TLS libraries where applicable.
#   If enabled, clients will encrypt all log data being sent to the given log servers.
#   Also, all log servers specified to use TLS (see tls_tcp_server) will load the imtcp
#   libraries and set the ncessary global NetStreamDriver information.
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
# [*allow_failover*]
# Type: Boolean
# Default: $::rsyslog::params::allow_failover
#   A flag to toggle whether RSyslog clients will implement failover for remote rules.
#   If enabled, clients will, in the order listed in failover_log_servers, failover to
#   each server as necessary.
#
# [*failover_log_servers*]
# Type: Array of hosts
# Default: $::rsyslog::params::failover_log_servers
#   A list of the failover RSyslog servers. If allow_failover servers is enabled, then
#   this order-dependent list will serve as all of the possible failover log servers for
#   clients to send to.
#
# [*is_server*]
# Type: Boolean
# Default: $::rsyslog::params::is_server
#   A flag to toggle whether this instance is a server or not. This mostly serves as a
#   legacy parameter, but is used for some validation.
#
# [*enable_firewall*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages firewall rules to accomodate RSyslog.
#
# [*enable_logging*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages logging (namely log rotation) for RSyslog.
#
# [*enable_pki*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages the PKI/PKE configuration for RSyslog.
#
# [*enable_selinux*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages SELinux rules for RSyslog.
#
# [*enable_tcpwrappers*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages the TCPWrappers configuration for RSyslog.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class rsyslog (
  $service_name          = $::rsyslog::params::service_name,
  $package_name          = $::rsyslog::params::package_name,
  $tls_package_name      = $::rsyslog::params::tls_package_name,
  $client_nets           = $::rsyslog::params::client_nets,
  $tcp_server            = $::rsyslog::params::tcp_server,
  $tcp_listen_port       = $::rsyslog::params::tcp_listen_port,
  $enable_tls            = $::rsyslog::params::enable_tls,
  $tls_tcp_server        = $::rsyslog::params::tls_tcp_server,
  $tls_listen_port       = $::rsyslog::params::tls_listen_port,
  $udp_server            = $::rsyslog::params::udp_server,
  $udp_server_address    = $::rsyslog::params::udp_server_address,
  $udp_listen_port       = $::rsyslog::params::udp_listen_port,
  $allow_failover        = $::rsyslog::params::allow_failover,
  $failover_log_servers  = $::rsyslog::params::failover_log_servers,
  $is_server             = $::rsyslog::params::is_server,
  $enable_firewall       = defined('$::use_iptables') ? { true => $::use_iptables, default => hiera('use_iptables',true) },
  $enable_logging        = defined('$::enable_logging') ? { true => $::enable_logging, default => hiera('enable_logging',true) },
  $enable_pki            = defined('$::enable_pki') ? { true => $::enable_pki, default => hiera('enable_pki',true) },
  $enable_selinux = defined('$::enable_selinux') ? { true => $::enable_selinux, default => hiera('enable_selinux',true) },
  $enable_tcpwrappers    = defined('$::enable_tcpwrappers') ? { true => $::enable_tcpwrappers, default => hiera('enable_tcpwrappers',true) }
) inherits rsyslog::params {
  validate_string($service_name)
  validate_string($package_name)
  validate_string($tls_package_name)
  validate_net_list($client_nets)
  validate_bool($tcp_server)
  validate_port($tcp_listen_port)
  validate_bool($enable_tls)
  validate_bool($tls_tcp_server)
  validate_port($tls_listen_port)
  validate_bool($udp_server)
  validate_net_list($udp_server_address)
  validate_port($udp_listen_port)
  validate_bool($allow_failover)
  if $allow_failover {
    if empty($failover_log_servers) {
      fail("Rsyslog specified to allow failover when no failover servers have been defined. You must have at least two log servers listed in the log_servers variable in hiera for failover to work properly.")
    }
    validate_net_list($failover_log_servers)
  }
  validate_bool($is_server)
  validate_bool($enable_firewall)
  validate_bool($enable_logging)
  validate_bool($enable_pki)
  validate_bool($enable_tcpwrappers)

  include '::rsyslog::install'
  include '::rsyslog::config'
  include '::rsyslog::service'

  Class['rsyslog::install'] ->
  Class['rsyslog::config'] ~>
  Class['rsyslog::service'] ->
  Class['rsyslog']

  if $enable_firewall {
    include '::rsyslog::config::firewall'
    Class['rsyslog::config::firewall'] ->
    Class['rsyslog::service']
  }

  if $enable_logging {
    include '::rsyslog::config::logging'
    Class['rsyslog::config::logging'] ->
    Class['rsyslog::service']
  }

  if $enable_pki {
    include '::rsyslog::config::pki'
    Class['rsyslog::config::pki'] ->
    Class['rsyslog::service']
  }

  if $enable_selinux {
    include '::rsyslog::config::selinux'
    Class['rsyslog::config::selinux'] ->
    Class['rsyslog::service']
  }

  if $enable_tcpwrappers {
    include '::rsyslog::config::tcpwrappers'
    Class['rsyslog::config::tcpwrappers'] ->
    Class['rsyslog::service']
  }
}
