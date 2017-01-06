# Set up rsyslog 7
#
# The configuration is particularly slanted toward the issues present in the
# version of rsyslog included with Enterprise Linux systems. It should still
# work on other systems but they may have different/other bugs that have not
# been addressed.
#
# @param service_name
#   The name of the RSyslog service; typically ``rsyslog``
#
# @param package_name
#   The name of the Rsyslog package to install; typically ``rsyslog``
#
# @param tls_package_name
#   The name of the Rsyslog package to install TLS utilities; typically ``rsyslog-gnutls``
#
# @param trusted_nets
#   A whitelist of subnets (in CIDR notation) permitted access
#
#   * This will be used in conjunction with IPTables (if enabled)
#     to allow connections from within the given subnets.
#
# @param enable_tls_logging
#   Enable the TLS libraries where applicable
#
#   * If enabled, clients will encrypt all log data being sent to the given log
#     servers.  Also, all log servers specified to use TLS (see
#     ``rsyslog::server::tls_tcp_server``) will load the ``imtcp`` libraries
#     and set the necessary global ``NetStreamDriver`` information.
#
# @param log_servers
#   A list of primary RSyslog servers
#
#   * All nodes in this list will get a copy of **all** logs if remote logging
#     is enabled.
#
# @param failover_log_servers
#   A list of the failover RSyslog servers
#
#   * This **order-dependent** list will serve as all of the possible failover
#     log servers for clients to send to if the servers in ``log_servers`` are
#     unavailable.
#
# @param queue_spool_directory
#   The path to the directory where RSyslog should store disk message queues
#
# @param rule_dir
#   The path at which all managed rules will begin
#
# @param tcp_server
#   Make this host listen for ``TCP`` connections
#
#   * Ideally, all connections would be ``TLS`` enabled. Only enable this if
#     necessary.
#
# @param tcp_listen_port
#   The port upon which to listen for regular ``TCP`` connections
#
# @param tls_tcp_server
#   Make this host listen for ``TLS`` enabled ``TCP`` connections
#
# @param tls_tcp_listen_port
#   The port upon which to listen for ``TLS`` enabled ``TCP`` connections
#
# @param udp_server
#   Make this host listend for ``UDP`` connections
#
#   * This really should not be enabled unless you have devices that cannot
#     speak ``TLS`` @param enable_logrotate
# @param udp_listen_address
#   The address upon which to listen for ``UDP`` connections
#
#   * The default of ``127.0.0.1`` is set primariliy for supporting Java
#     applications that cannot work with a modern method of logging.
#
# @param udp_listen_port
#   The port upon which to listen for ``UDP`` connections
#
# @param read_journald
#   Enable the processing of ``journald`` messages natively in Rsyslog
#
# @param logrotate
#   Ensure that ``logrotate`` is enabled on this system
#
#   * You will need to configure specific logrotate settings via the
#   ``logrotate`` module.
#
# @param pki
#   Enable SIMP management of PKI keys
#
#   * Options
#       * 'simp' => Use the SIMP key distribution mechanism
#       * true   => Use the ``pki::copy`` method
#       * false  => Do not manage the PKI keys, you're on your own
#
# @param pki_base_dir
#   The location, on disk, for the module's PKI certificates
#
#   * By default, we expect the certificates to be in a ``pki`` subdirectory of
#     ``pki_base_dir`` so this should not be included in your path.
#
#   * The default expected directory structure is:
#       * ``pki_base_dir``/pki/cacerts
#           * All CA Certificates in PEM format with Hash-based aliases
#       * ``pki_base_dir``/pki/cacerts/cacerts.pem
#           * All CA Certificates in a single PEM file
#       * ``pki_base_dir``/pki/public/${``facts['fqdn']``}.pub
#           * The daemon's public X.509 Certificate in PEM format
#       * ``pki_base_dir``/pki/private/${``facts['fqdn']``}.pem
#           * The daemon's private RSA key in PEM format
#
# @author Chris Tessmer <chris.tessmer@onyxpoint.com>
# @author Kendall Moore <kendall.moore@onyxpoint.com>
# @author Mike Riddle <mike.riddle@onyxpoint.com>
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsyslog (
  String                        $service_name          = $::rsyslog::params::service_name,
  String                        $package_name          = $::rsyslog::params::package_name,
  String                        $tls_package_name      = $::rsyslog::params::tls_package_name,
  Simplib::Netlist              $trusted_nets          = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.0.1/32'] }),
  Boolean                       $enable_tls_logging    = false,
  Simplib::Netlist              $log_servers           = simplib::lookup('simp_options::syslog::log_servers', { 'default_value' => [] }),
  Simplib::Netlist              $failover_log_servers  = simplib::lookup('simp_options::syslog::failover_log_servers', { 'default_value' => [] }),
  Stdlib::Absolutepath          $queue_spool_directory = '/var/spool/rsyslog',
  Stdlib::Absolutepath          $rule_dir              = '/etc/rsyslog.simp.d',
  Boolean                       $tcp_server            = false,
  Simplib::Port                 $tcp_listen_port       = 514,
  Boolean                       $tls_tcp_server        = false,
  Simplib::Port                 $tls_tcp_listen_port   = 6514,
  Boolean                       $udp_server            = false,
  String                        $udp_listen_address    = '127.0.0.1',
  Simplib::Port                 $udp_listen_port       = 514,
  Boolean                       $read_journald         = $::rsyslog::params::read_journald,
  Boolean                       $logrotate             = simplib::lookup('simp_options::logrotate', {'default_value' => false}),
  Variant[Boolean,Enum['simp']] $pki                   = simplib::lookup('simp_options::pki', {'default_value' => false}),
  Stdlib::Absolutepath          $pki_base_dir          = '/etc/rsyslog.d'
) inherits ::rsyslog::params {

  contain '::rsyslog::install'
  contain '::rsyslog::config'
  contain '::rsyslog::service'

  Class['rsyslog::install'] ->
  Class['rsyslog::config'] ~>
  Class['rsyslog::service']

  if $logrotate {
    contain '::rsyslog::config::logrotate'
    Class['rsyslog::service'] -> Class['rsyslog::config::logrotate']
  }

  if $pki {
    contain '::rsyslog::config::pki'
    Class['rsyslog::config::pki'] -> Class['rsyslog::config']
    Class['rsyslog::config::pki'] ~> Class['rsyslog::service']
  }
}
