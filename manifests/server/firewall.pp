# @summary Sets up the firewall rules for RSyslog with management by ``simp/iptables``
#
# In ports will be openened for all systems inside of the
# ``$rsyslog::trusted_nets`` Array.
#
# Each rule follows its listener's parameter:
#
# * `true` opens the port.
# * `false` leaves the port out, which removes the rule.
# * undef keeps the port open while the listener is still configured, so that
#   a later run that no longer sets the parameter does not cut clients off.
#
# @api private
#
class rsyslog::server::firewall {
  assert_private()

  simplib::assert_optional_dependency($module_name, 'simp/iptables')

  $_inputs = pick($facts.dig('rsyslog_simp_config', 'inputs'), [])

  $_tls_listening = !$_inputs.filter |$i| {
    $i['type'] == 'imtcp' and $i['port'] == $rsyslog::tls_tcp_listen_port
  }.empty
  # The TLS listener's plain imptcp companion was never opened in the firewall
  $_tcp_listening = !$_inputs.filter |$i| {
    $i['type'] == 'imtcp' and $i['port'] == $rsyslog::tcp_listen_port
  }.empty
  $_udp_listening = !$_inputs.filter |$i| {
    $i['type'] == 'imudp' and $i['port'] == $rsyslog::udp_listen_port
  }.empty

  if $rsyslog::tls_tcp_server or ($rsyslog::tls_tcp_server =~ Undef and $_tls_listening) {
    iptables::listen::tcp_stateful { 'syslog_tls_tcp':
      trusted_nets => $rsyslog::trusted_nets,
      dports       => $rsyslog::tls_tcp_listen_port
    }
  }

  if $rsyslog::tcp_server or ($rsyslog::tcp_server =~ Undef and $_tcp_listening) {
    iptables::listen::tcp_stateful { 'syslog_tcp':
      trusted_nets => $rsyslog::trusted_nets,
      dports       => $rsyslog::tcp_listen_port
    }
  }

  if $rsyslog::udp_server or ($rsyslog::udp_server =~ Undef and $_udp_listening) {
    iptables::listen::udp { 'syslog_udp':
      trusted_nets => $rsyslog::trusted_nets,
      dports       => $rsyslog::udp_listen_port
    }
  }
}
