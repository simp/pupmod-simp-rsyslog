# == Class rsyslog::params
#
# A list of the parameters and their default values for RSyslog.
#
# == Authors
#
# * Kendall Moore <kmoore@keywcorp.com>
# * Mike Riddle <mriddle@onyxpoint.com>
#
class rsyslog::params {
  $service_name       = 'rsyslog'
  $package_name       = 'rsyslog'
  $tls_package_name   = 'rsyslog-gnutls'
  $client_nets        = hiera_array('client_nets', ['127.0.0.1/32'])
  $log_server_list    = hiera_array('log_servers', [])
  if !empty($log_server_list) and (size($log_server_list) > 1) {
    $failover_log_servers = delete_at($log_server_list, 0)
  }
  else {
    $failover_log_servers = []
  }
  $enable_tls         = false
  $tcp_server         = false
  $tcp_listen_port    = '514'
  $tls_tcp_server     = false
  $tls_listen_port    = '6514'
  $udp_server         = false
  $udp_server_address = '127.0.0.1'
  $udp_listen_port    = '514'
  $allow_failover     = false
}
