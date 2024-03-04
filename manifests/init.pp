# @summary Set up Rsyslog 8
#
# The configuration is particularly slanted toward the issues present in the
# versions of rsyslog included with Enterprise Linux systems. It should still
# work on other systems but they may have different/other bugs that have not
# been addressed.
#
# See ``rsyslog::config`` for additional, detailed configuration.
#
# @param service_name
#   The name of the Rsyslog service; typically ``rsyslog``
#
# @param package_name
#   The name of the Rsyslog package to install; typically ``rsyslog``
#
# @param tls_package_name
#   The name of the Rsyslog package to install TLS utilities; typically ``rsyslog-gnutls``
#
# @param trusted_nets
#   A list of subnets (in CIDR notation) permitted access
#
#   * This will be used in conjunction with ``simp\iptables`` (if enabled)
#     to allow connections from within the given subnets.
#
# @param enable_tls_logging
#   Enable the TLS libraries where applicable
#
#   * If enabled, clients will encrypt all log data being sent to the given log
#     servers.  Also, all log servers specified to use TLS (see
#     ``rsyslog::server::tls_tcp_server``) will load the ``imtcp`` module and
#     configure it for TLS.
#
# @param log_servers
#   A list of primary Rsyslog servers
#
#   * All nodes in this list will get a copy of **all** logs if remote logging
#     is enabled.
#
# @param failover_log_servers
#   A list of the failover Rsyslog servers
#
#   * This **order-dependent** list will serve as all of the possible failover
#     log servers for clients to send to if the servers in ``log_servers`` are
#     unavailable.
#
# @param queue_spool_directory
#   The path to the directory where Rsyslog should store disk message queues
#
# @param rule_dir
#   The path at which all managed rules will begin
#
# @param tcp_server
#   Make this host listen for ``TCP`` connections
#
#   * Ideally, all connections would be ``TLS`` enabled via ``$tls_tcp_server``
#     instead.
#   * Only enable this if necessary.
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
#   Make this host listen for ``UDP`` connections
#
#   * This really should not be enabled unless you have devices that cannot
#     speak ``TLS``
#
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
#   * If 'simp', include SIMP's pki module and use pki::copy to manage
#     application certs in /etc/pki/simp_apps/rsyslog/x509
#   * If true, do *not* include SIMP's pki module, but still use pki::copy
#     to manage certs in /etc/pki/simp_apps/rsyslog/x509
#   * If false, do not include SIMP's pki module and do not use pki::copy
#     to manage certs.  You will need to appropriately assign a subset of:
#     * app_pki_dir
#     * app_pki_key
#     * app_pki_cert
#     * app_pki_ca
#     * app_pki_ca_dir
#
# @param app_pki_external_source
#   * If pki = 'simp' or true, this is the directory from which certs will be
#     copied, via pki::copy.  Defaults to /etc/pki/simp/x509.
#
#   * If pki = false, this variable has no effect.
#
# @param app_pki_dir
#   Basepath of $default_net_stream_driver_ca_file, default_net_stream_driver_cert_file,
#   and $default_net_stream_driver_key_file
#
# @param rules
#   A hash of rsyslog rules, this parameter will enable you to create rules via hieradata
#
# @example Create rules via hieradata:
#   rsyslog::rules:
#     'some_path/99_collect_kernel_errors.conf':
#       content: "if prifilt('kern.err') then /var/log/kernel_errors.log"
#     'some_path/98_discard_info.conf':
#       content: "if prifilt('*.info') then stop"
#
# @author https://github.com/simp/pupmod-simp-rsyslog/graphs/contributors
#
class rsyslog (
  String                        $service_name            = 'rsyslog',
  String                        $package_name            = 'rsyslog',
  Boolean                       $read_journald           = true,
  String                        $tls_package_name        = "${package_name}-gnutls",
  Simplib::Netlist              $trusted_nets            = simplib::lookup('simp_options::trusted_nets', {'default_value'                  => ['127.0.0.1/32'] }),
  Boolean                       $enable_tls_logging      = false,
  Simplib::Netlist              $log_servers             = simplib::lookup('simp_options::syslog::log_servers', { 'default_value'          => [] }),
  Simplib::Netlist              $failover_log_servers    = simplib::lookup('simp_options::syslog::failover_log_servers', { 'default_value' => [] }),
  Stdlib::Absolutepath          $queue_spool_directory   = '/var/spool/rsyslog',
  Stdlib::Absolutepath          $rule_dir                = '/etc/rsyslog.simp.d',
  Boolean                       $tcp_server              = false,
  Simplib::Port                 $tcp_listen_port         = 514,
  Boolean                       $tls_tcp_server          = false,
  Simplib::Port                 $tls_tcp_listen_port     = 6514,
  Boolean                       $udp_server              = false,
  String                        $udp_listen_address      = '127.0.0.1',
  Simplib::Port                 $udp_listen_port         = 514,
  Boolean                       $logrotate               = simplib::lookup('simp_options::logrotate', {'default_value'                     => false}),
  Variant[Boolean,Enum['simp']] $pki                     = simplib::lookup('simp_options::pki', {'default_value'                           => false}),
  String                        $app_pki_external_source = simplib::lookup('simp_options::pki::source', {'default_value'                   => '/etc/pki/simp/x509'}),
  Stdlib::Absolutepath          $app_pki_dir             = '/etc/pki/simp_apps/rsyslog/x509',
  Optional[Hash]                $rules                   = undef
) {
  if $facts['rsyslogd'] and versioncmp($facts['rsyslogd']['version'], '8.24.0') < 0  {
    warning("${module_name}: Rsyslog version ${facts['rsyslogd']} not supported. Use ${module_name} version 7.6.4 instead")
  }

  contain 'rsyslog::install'
  contain 'rsyslog::config'
  contain 'rsyslog::service'

  # lint:ignore:arrow_on_right_operand_line
  Class['rsyslog::install'] ->
  Class['rsyslog::config'] ~>
  Class['rsyslog::service']
  # lint:endignore

  if $logrotate {
    contain 'rsyslog::config::logrotate'
    Class['rsyslog::service'] -> Class['rsyslog::config::logrotate']
  }

  $rsyslog::rules.each |$key, $value| {
    rsyslog::rule { $key:
      * => $value,
    }
  }
}
