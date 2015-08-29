# == Class rsyslog::params
#
# A list of the parameters and their default values for RSyslog.
#
class rsyslog::params {
  $service_name       = 'rsyslog'
  if ($::operatingsystem in ['RedHat','CentOS']) and
     ("${::operatingsystemmajrelease}" == '6') {
       $package_name = 'rsyslog7'
  }
  else {
    $package_name = 'rsyslog'
  }

  $tls_package_name = "${package_name}-gnutls"
  $client_nets      =  defined('$::client_nets') ? { true => $::client_nets, default => hiera('client_nets', ['127.0.0.1/32']) }
  $log_server_list  = defined('$::log_servers') ? { true => $::log_servers, default => hiera('log_servers', []) }

  if !empty($log_server_list) and (size($log_server_list) > 1) {
    $failover_log_servers = delete_at($log_server_list, 0)
  }
  else {
    $failover_log_servers = []
  }
  $enable_tls_logging = false
  $tcp_server         = false
  $tcp_listen_port    = '514'
  $tls_tcp_server     = false
  $tls_listen_port    = '6514'
  $udp_server         = false
  $udp_listen_address = '127.0.0.1'
  $udp_listen_port    = '514'
  $allow_failover     = false
}
