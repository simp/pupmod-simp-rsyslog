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
# Type: String
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
# [*enable_tls_logging*]
# Type: Boolean
# Default: $::rsyslog::params::manage_tls_login
#   A flag to toggle whether RSyslog should enable the TLS libraries where applicable.
#   If enabled, clients will encrypt all log data being sent to the given log servers.
#   Also, all log servers specified to use TLS (see rsyslog::server::tls_tcp_server) will
#   load the imtcp libraries and set the necessary global NetStreamDriver information.
#
# [*allow_failover*]
# Type: Boolean
# Default: $::rsyslog::params::allow_failover
#   A flag to toggle whether RSyslog clients will implement failover for remote
#   rules.  If enabled, clients will, in the order listed in
#   failover_log_servers, failover to
#   each server as necessary.
#
# [*failover_log_servers*]
# Type: Array of hosts
# Default: $::rsyslog::params::failover_log_servers
#   A list of the failover RSyslog servers. If allow_failover servers is
#   enabled, then this order-dependent list will serve as all of the possible
#   failover log servers for clients to send to.
#
# [*rule_dir*]
# Type: Absolute Path
# Default: /etc/rsyslog.simp.d
#   The path at which all managed rules will begin.
#
# [*manage_logging*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, manages logging (namely log rotation) for RSyslog.
#
# [*manage_pki_certs*]
# Type: Boolean
# Default: true
#   A flag, which if enabled, allows SIMP to distribute PKI certs/keys for Rsyslog.
#
# [*cert_source*]
# Type: String
# Default: ''
#   The path to client certificates dir, if using local (SIMP-independent) PKI
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Chris Tessmer <mailto:chris.tessmer@onyxpoint.com>
#
class rsyslog (
  $service_name          = $::rsyslog::params::service_name,
  $package_name          = $::rsyslog::params::package_name,
  $tls_package_name      = $::rsyslog::params::tls_package_name,
  $client_nets           = $::rsyslog::params::client_nets,
  $log_server_list       = $::rsyslog::params::log_server_list,
  $enable_tls_logging    = $::rsyslog::params::enable_tls_logging,
  $allow_failover        = $::rsyslog::params::allow_failover,
  $failover_log_servers  = $::rsyslog::params::failover_log_servers,
  $tcp_server            = $::rsyslog::params::tcp_server,
  $tcp_listen_port       = $::rsyslog::params::tcp_listen_port,
  $tls_tcp_server        = $::rsyslog::params::tls_tcp_server,
  $tls_listen_port       = $::rsyslog::params::tls_listen_port,
  $udp_server            = $::rsyslog::params::udp_server,
  $udp_listen_address    = $::rsyslog::params::udp_listen_address,
  $udp_listen_port       = $::rsyslog::params::udp_listen_port,
  $rule_dir              = '/etc/rsyslog.simp.d',
  $manage_logging        = defined('$::manage_logging') ? { true => $::manage_logging, default => hiera('manage_logging',true) },
  $manage_pki_certs      = defined('$::manage_pki_certs') ? { true => $::manage_pki_certs, default => hiera('manage_pki_certs',true) },
  $cert_source           = '/etc/rsyslog.d/pki',
) inherits ::rsyslog::params {
  validate_string($service_name)
  validate_string($package_name)
  validate_string($tls_package_name)
  validate_net_list($client_nets)
  validate_bool($enable_tls_logging)
  validate_bool($allow_failover)
  if $allow_failover {
    if empty($failover_log_servers) {
      fail('Rsyslog specified to allow failover when no failover servers have been defined. You must have at least two log servers listed in the log_servers variable in hiera for failover to work properly.')
    }
    validate_net_list($failover_log_servers)
  }
  validate_bool($tcp_server)
  validate_bool($tls_tcp_server)
  validate_bool($udp_server)
  validate_bool($manage_logging)
  validate_bool($manage_pki_certs)
  validate_string($cert_source)

  include '::rsyslog::install'
  include '::rsyslog::config'
  include '::rsyslog::service'

  Class['rsyslog::install'] ->
  Class['rsyslog::config'] ~>
  Class['rsyslog::service'] ->
  Class['rsyslog']

  if $manage_logging {
    include '::rsyslog::config::logging'
    Class['rsyslog::config::logging'] ->
    Class['rsyslog::service']
  }

  if $manage_pki_certs {
    include '::rsyslog::config::pki_certs'
    Class['rsyslog::config::pki_certs'] ~>
    Class['rsyslog::service']
  }
}
