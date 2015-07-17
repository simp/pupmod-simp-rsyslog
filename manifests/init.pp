# == Class: rsyslog
#
# Set up rsyslogd
#
# It is assumed that local6 will be used for all logs collected from files.
#
# You will need to add a rule specifically for this if you want to send them to
# a remote host.
#
# == Parameters
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
