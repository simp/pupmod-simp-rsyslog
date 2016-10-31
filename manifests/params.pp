# == Class rsyslog::params
#
# A list of the parameters and their default values for RSyslog.
#
class rsyslog::params {
  $service_name       = 'rsyslog'
  if ($::operatingsystem in ['RedHat','CentOS']) and ($::operatingsystemmajrelease == '6') {
    $package_name  = 'rsyslog7'
    $read_journald = false
  }
  else {
    $package_name  = 'rsyslog'
    $read_journald = true
  }

  $tls_package_name = "${package_name}-gnutls"

  $client_nets      =  defined('$::client_nets') ?
    { true => $::client_nets, default => hiera('client_nets', ['127.0.0.1/32']) }

  $log_server_list  = defined('$::log_servers') ?
    { true => $::log_servers, default => hiera('log_servers', []) }

  $failover_log_servers = defined('$::failover_log_servers') ?
    { true => $::failover_log_servers, default => hiera('failover_log_servers', []) }

  $enable_tls_logging = false
  $tcp_server         = false
  $tcp_listen_port    = '514'
  $tls_tcp_server     = false
  $tls_listen_port    = '6514'
  $udp_server         = false
  $udp_listen_address = '127.0.0.1'
  $udp_listen_port    = '514'
}
