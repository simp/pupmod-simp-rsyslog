# Sets up the RSyslog server
#
# This class is designed to configure the externally facing interfaces for a
# RSyslog system. If you do not need external connectivity, you should just use
# the stock ``::rsyslog`` Class.
#
# @param enable_firewall
#   Enable the SIMP firewall rules for RSyslog
#
# @param enable_selinux
#   Enable the SIMP SELinux rules for RSyslog
#
# @param enable_tcpwrappers
#   Enable the SIMP TCPWrapper rules for RSyslog
#
class rsyslog::server (
  Boolean           $enable_firewall    = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Optional[Boolean] $enable_selinux     = $facts['selinux_enforced'],
  Boolean           $enable_tcpwrappers = simplib::lookup('simp_options::tcpwrappers', { 'default_value' => false })
) {
  include '::rsyslog'

  if $enable_firewall {
    contain '::rsyslog::server::firewall'

    Class['rsyslog::service'] -> Class['rsyslog::server::firewall']
  }

  if $enable_selinux {
    contain '::rsyslog::server::selinux'

    Class['rsyslog::server::selinux'] -> Class['rsyslog::service']
  }

  if $enable_tcpwrappers {
    contain '::rsyslog::server::tcpwrappers'

    Class['rsyslog::service'] -> Class['rsyslog::server::tcpwrappers']
  }
}
