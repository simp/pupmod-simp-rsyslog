# @summary Setup Rsyslog configuration
# - Creates /etc/rsyslog.conf that includes all SIMP config subdirectories
#   in /etc/rsyslog.simp.d and then populates /etc/rsyslog.simp.d.
# - When the host uses rsyslog version 8.24.0, creates a rsyslog.service
#   override file that fixes a service ordering problem present with older
#   versions of rsyslog.
#
# **NOTE** Any undocumented parameters map directly to their counterparts in
# the Rsyslog configuration files.
#
# @param umask
#   The umask that should be applied to the running process
#
# @param localhostname
#   The Hostname that should be used on your syslog messages
#
# @param preserve_fqdn
#   Ensure that the ``fqdn`` of the originating host is preserved in all log
#   messages
#
# @param escape_control_characters_on_receive
#   Replace control characters during reception of the message
#
# @param control_character_escape_prefix
#  The prefix character to be used for control character escaping
#
# @param drop_msgs_with_malicious_dns_ptr_records
#  Drop messages for which Rsyslog had detected malicious DNS PTR records
#
# @param default_template
#   **DEPRECATED**. Use ``default_file_template`` instead
#
# @param default_file_template
#   The default template to use to output to file
#
#   * Configures the omfile module.
#   * You can specify a built-in template name, custom template name or choose
#     from the following mappings to a subset of built-in rsyslogd templates:
#
#       * forward     -> RSYSLOG_Forward
#       * original    -> RSYSLOG_FileFormat
#       * traditional -> RSYSLOG_TraditionalFileFormat
#
#   * If you specify a custom template name, you must ensure the template is
#     configured.
#
#     * Use one of the `rsyslog::template:*` defines to configure the template.
#
# @param default_forward_template
#   The default template to use to forward
#
#   * Configures the omfwd module.
#   * You can specify a built-in or custom template name.
#   * If you specify a custom template name, you must ensure the template is
#     configured.
#
#     * Use one of the `rsyslog::template:*` defines to configure the template.
#
# @param syssock_ignore_timestamp
#   imuxsock module's SysSock.IgnoreTimestamp parameter
#
# @param syssock_ignore_own_messages
#   imuxsock module's SysSock.IgnoreOwnMessages parameter
#
# @param syssock_use
#   imuxsock module's SysSock.Use parameter
#
# @param syssock_name
#   imuxsock module's SysSock.Name parameter
#
# @param syssock_flow_control
#   imuxsock module's SysSock.FlowControl parameter
#
# @param syssock_use_pid_from_system
#   imuxsock module's SysSock.UsePIDFromSystem parameter
#
# @param syssock_rate_limit_interval
#   imuxsock module's SysSock.RateLimit.Interval parameter
#
# @param syssock_rate_limit_burst
#   imuxsock module's SysSock.RateLimit.Burst parameter
#
# @param syssock_rate_limit_severity
#   imuxsock module's SysSock.RateLimit.Severity parameter
#
# @param syssock_use_sys_timestamp
#   imuxsock module's SysSock.UseSysTimeStamp parameter
#
# @param syssock_annotate
#   imuxsock module's SysSock.Annotate parameter
#
# @param syssock_parse_trusted
#   imuxsock module's SysSock.ParseTrusted parameter
#
# @param syssock_unlink
#   imuxsock module's SysSock.Unlink parameter

# @param main_msg_queue_type
#   The type of queue that will be used
#
#   * It is **highly** recommended that you leave this as ``LinkedList`` unless
#     you really know what you are doing.
#
# @param main_msg_queue_filename
#   The file name to be used for the main (global) message queue
#
#   *  Should not contain the directory path.
#
# @param main_msg_queue_size
#   The size of the main (global) message queue
#
#   * By default, the minimum of 1% of physical memory or 1G, based on a 512B
#     message size. The maximum number of messages that may be stored in the
#     memory queue.
#
# @param main_msg_queue_high_watermark
#   The point at which the main (global) message queue will start writing
#   messages to disk as a number of messages
#
#   * By default, 90% of ``$main_msg_queue_size``
#
# @param main_msg_queue_low_watermark
#   The point at which the main (global) message queue will stop writing
#   messages to disk as a number of messages
#
#   * **NOTE:** This must be **lower** than ``$main_msg_queue_high_watermark``
#   * By default, 70% of ``$main_msg_queue_size``
#
# @param main_msg_queue_discardmark
#   The point at which the main (global) message queue will discard messages
#
#   * By default, 98% of ``$main_msg_queue_size``
#
# @param main_msg_queue_worker_thread_minimum_messages
#   The minimum number of messages in the main (global) message queue before
#   a new thread can be spawned
#
#   * If left empty (the default), will calculate the value based on the
#     following formula: ``$main_msg_queue_size/(($processorcount - 1)*4)``
#
# @param main_msg_queue_worker_threads
#   The maximum number of main (global) message queue worker threads to spawn
#   on the system
#
#   * By default, ``$processorcount - 1``
#
# @param main_msg_queue_timeout_enqueue
#  The timeout value in milliseconds to use when the main (global) message queue
#  is full. If rsyslog cannot enqueue a message within the timeout period, the
#  message is discarded
#
# @param main_msg_queue_dequeue_slowdown
#  The timeout value in microseconds to use for simple rate limiting in the
#  main (global) message queue
#
# @param main_msg_queue_save_on_shutdown
#  Whether data fro mthe main (global) message queue should be saved at
#  shutdown
#
# @param main_msg_queue_max_disk_space
#   The maximum amount of disk space to use for the main (global) disk queue
#
#   * Specified as a digit followed by a unit specifier. For example:
#
#       * 100   -> 100 Bytes
#       * 100K  -> 100 Kilobytes
#       * 100M  -> 100 Megabytes
#       * 100G  -> 100 Gigabytes
#       * 100T  -> 100 Terabytes
#       * 100P  -> 100 Petabytes
#
#   * If not specified, will default to ``$main_msg_queue_size * 1024``
#
# @param main_msg_queue_max_file_size
#   The maximum file size, in Megabytes, that should be created when buffering
#   to disk
#
#   * **NOTE:** It is not recommended to make this excessively large
#
# @param repeated_msg_reduction
#   Reduce repeated messages to a single "Last line repeated n times" message
#
# @param work_directory
#   The directory that rsyslog uses for work files, e.g. imfile state or queue spool files
#
# @param tls_tcp_max_sessions
#   The maximum number of sessions to support
#
# @param tls_input_tcp_server_stream_driver_permitted_peers
#   A *wildcard-capable* Array of domains that should be allowed to talk to the
#   server over ``TLS``
#
# @param keep_alive
#   imtcp module's KeepAlive parameter
#
#   * Only applies when either $rsyslog::tcp_server` or
#     `$rsyslog::tls_tcp_server` is set to `true`
#
# @param keep_alive_probes
#   imtcp module's KeepAliveProves parameter
#
#   * Only applies when either $rsyslog::tcp_server` or
#     `$rsyslog::tls_tcp_server` is set to `true`
#
# @param keep_alive_time
#   imtcp module's KeepAliveTime parameter
#
#   * Only applies when either $rsyslog::tcp_server` or
#     `$rsyslog::tls_tcp_server` is set to `true`
#
# @param default_net_stream_driver
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   defaultNetStreamDriver configuration parameter.
#
# @param default_net_stream_driver_ca_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   defaultNetStreamDriverCAFile configuration parameter. Currently, this
#   is the **ONLY** mechanism available to set the CA file for ``TLS``.
#
# @param default_net_stream_driver_cert_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   global defaultNetStreamDriverCertFile configuration parameter. Currently,
#   this is the **ONLY** mechanism available to set the cert file for ``TLS``.
#
# @param default_net_stream_driver_key_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   used to set the global defaultNetStreamDriverKeyFile configuration
#   parameter. Currently, this is the **ONLY** mechanism available to set the
#   key file for ``TLS``.
#
# @param action_send_stream_driver_mode
#   **DEPRECATED** Use ``imtcp_stream_driver_mode.
#
# @param imtcp_stream_driver_mode
#
#   * When ``$rsyslog::tls_tcp_server = true``, used to set the imtcp module's
#     default StreamDriver.Mode
#
# @param action_send_stream_driver_auth_mode
#   **DEPRECATED** Use ``imtcp_stream_driver_auth_mode``.
#
# @param imtcp_stream_driver_auth_mode
#
#   * When ``$rsyslog::tls_tcp_server = true``, used to set the imtcp module's
#     default StreamDriver.AuthMode.  If undefined, this value is set based on
#     ``$imtcp_stream_driver_mode``.
#
# @param ulimit_max_open_files
#   The maximum open files limit that should be set for the syslog server
#
#   * ``1024`` is fine for most purposes, but a collection server should bump this
#     **way** up.
#
# @param enable_default_rules
#   Enables default rules for logging common services (e.g., firewall, puppet, slapd_auditd)
#
# @param suppress_noauth_warn
#   **DEPRECATED**. Use ``net_permit_acl_warning`` instead.
#
# @param net_permit_acl_warning
#   Allow warnings issued when messages are received from non-authorized machines
#
# @param disable_remote_dns
#   **DEPRECATED**. Use ``net_enable_dns`` instead.
#
# @param net_enable_dns
#   Enable DNS name resolution
#
# @param read_journald
#   Enable the forwarding of the ``systemd`` journal to syslog
#
# @param include_rsyslog_d
#   Include all configuration files in the system-standard ``/etc/rsyslog.d``
#
#   * This will place the configuration files **after** the global
#     configuration but **before** the SIMP applied configurations.
#
# @param systemd_override_file
#   The basename of the systemd override file for the rsyslog service
#
#   * Only used for rsyslog version 8.24.0 (EL7).
#
# @param extra_global_params
#   Additional global parameters to be added to 00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @param extra_legacy_globals
#   Additional Legacy-style global parameters to be added to
#   00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @param extra_imfile_mod_params
#   Additional imfile module parameters to be added to the imfile load
#   statement in 00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @param extra_imjournal_mod_params
#   Additional imjournal module parameters to be added to the imjournal load
#   statement in 00_simp_pre_logging/global.conf
#
#   * Only applies when `$rsyslog::read_journald` is set to `true`
#   * No validation of parameter names or values is done
#
# @param extra_imklog_mod_params
#   Additional imklog module parameters to be added to the imklog load
#   statement in 00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @param extra_imptcp_mod_params
#   Additional imptcp module parameters to be added to the imptcp load
#   statement in 00_simp_pre_logging/global.conf
#
#   * Only applies when $rsyslog::tls_tcp_server` is set to `true`
#   * No validation of parameter names or values is done
#
# @param extra_imtcp_mod_params
#   Additional imtcp module parameters to be added to the imtcp load
#   statement in 00_simp_pre_logging/global.conf
#
#   * Only applies when either $rsyslog::tcp_server` or
#     `$rsyslog::tls_tcp_server` is set to `true`
#   * No validation of parameter names or values is done
#
# @param extra_imudp_mod_params
#   Additional imudp module parameters to be added to the imudp load
#   statement in 00_simp_pre_logging/global.conf
#
#   * Only applies when `$rsyslog::udp_server` is set to `true`
#   * No validation of parameter names or values is done
#
# @param extra_imuxsock_mod_params
#   Additional imuxsock module parameters to be added to the imuxsock load
#   statement in 00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @param extra_main_queue_params
#   Additional main queue parameters to be added to the main_queue
#   configuration statement in 00_simp_pre_logging/global.conf
#
#   * No validation of parameter names or values is done
#
# @api private
class rsyslog::config (
  Simplib::Umask                        $umask                                              = '0027',
  String                                $localhostname                                      = $facts['networking']['fqdn'],
  Rsyslog::Boolean                      $preserve_fqdn                                      = true,
  String[1,1]                           $control_character_escape_prefix                    = '#',
  Rsyslog::Boolean                      $drop_msgs_with_malicious_dns_ptr_records           = false,
  Rsyslog::Boolean                      $escape_control_characters_on_receive               = true,
  Optional[String]                      $default_template                                   = undef,
  String[1]                             $default_file_template                              = 'RSYSLOG_FileFormat',
  String[1]                             $default_forward_template                           = 'RSYSLOG_ForwardFormat',

  # Parameters for imuxsock with sensible defaults
  Rsyslog::Boolean                      $syssock_ignore_timestamp                           = true,
  Rsyslog::Boolean                      $syssock_ignore_own_messages                        = true,
  Rsyslog::Boolean                      $syssock_use                                        = true,
  Optional[String[1]]                   $syssock_name                                       = undef,
  Rsyslog::Boolean                      $syssock_flow_control                               = false,
  Rsyslog::Boolean                      $syssock_use_pid_from_system                        = false,
  Integer[0]                            $syssock_rate_limit_interval                        = 0,
  Integer[0]                            $syssock_rate_limit_burst                           = 1000,
  Integer[0]                            $syssock_rate_limit_severity                        = 5,
  Rsyslog::Boolean                      $syssock_use_sys_timestamp                          = true,
  Rsyslog::Boolean                      $syssock_annotate                                   = false,
  Rsyslog::Boolean                      $syssock_parse_trusted                              = false,
  Rsyslog::Boolean                      $syssock_unlink                                     = true,

  # Main message queue global defaults
  Rsyslog::QueueType                    $main_msg_queue_type                                = 'LinkedList',
  String[1]                             $main_msg_queue_filename                            = 'main_msg_queue',
  Integer[0]                            $main_msg_queue_max_file_size                       = 5,
  Optional[Integer[0]]                  $main_msg_queue_size                                = undef,
  Optional[Integer[0]]                  $main_msg_queue_high_watermark                      = undef,
  Optional[Integer[0]]                  $main_msg_queue_low_watermark                       = undef,
  Optional[Integer[0]]                  $main_msg_queue_discardmark                         = undef,
  Optional[Integer[0]]                  $main_msg_queue_worker_thread_minimum_messages      = undef,
  Optional[Integer[0]]                  $main_msg_queue_worker_threads                      = undef,
  Integer[0]                            $main_msg_queue_timeout_enqueue                     = 100,
  Integer[0]                            $main_msg_queue_dequeue_slowdown                    = 0,
  Rsyslog::Boolean                      $main_msg_queue_save_on_shutdown                    = true,
  Optional[Integer[0]]                  $main_msg_queue_max_disk_space                      = undef,

  Rsyslog::Boolean                      $repeated_msg_reduction                             = true,
  Stdlib::Absolutepath                  $work_directory                                     = '/var/spool/rsyslog',
  Integer[0]                            $tls_tcp_max_sessions                               = 200,
  Array[String[1]]                      $tls_input_tcp_server_stream_driver_permitted_peers = ["*.${facts['networking']['domain']}"],
  Optional[Rsyslog::Boolean]            $keep_alive                                         = undef,
  Optional[Integer[0]]                  $keep_alive_probes                                  = undef,
  Optional[Integer[0]]                  $keep_alive_time                                    = undef,

  Enum['gtls','ptcp']                   $default_net_stream_driver                          = 'gtls',
  Stdlib::Absolutepath                  $default_net_stream_driver_ca_file                  = "${rsyslog::app_pki_dir}/cacerts/cacerts.pem",
  Stdlib::Absolutepath                  $default_net_stream_driver_cert_file                = "${rsyslog::app_pki_dir}/public/${facts['networking']['fqdn']}.pub",
  Stdlib::Absolutepath                  $default_net_stream_driver_key_file                 = "${rsyslog::app_pki_dir}/private/${facts['networking']['fqdn']}.pem",

  Optional[Enum['1','0']]               $action_send_stream_driver_mode                     = undef,
  Enum['1','0']                         $imtcp_stream_driver_mode                     = ($rsyslog::pki or $rsyslog::tls_tcp_server or $rsyslog::enable_tls_logging) ? { true => '1', default => '0' },
  Optional[String]                      $action_send_stream_driver_auth_mode                = undef,
  Optional[String]                      $imtcp_stream_driver_auth_mode                      = undef,

  Variant[Enum['unlimited'],Integer[0]] $ulimit_max_open_files                              = 'unlimited',
  Boolean                               $enable_default_rules                               = true,
  Optional[Boolean]                     $suppress_noauth_warn                               = undef,
  Rsyslog::Boolean                      $net_permit_acl_warning                             = true,
  Optional[Boolean]                     $disable_remote_dns                                 = undef,
  Rsyslog::Boolean                      $net_enable_dns                                     = true,

  Boolean                               $read_journald                                      = $rsyslog::read_journald,
  Boolean                               $include_rsyslog_d                                  = false,
  String                                $systemd_override_file                              = 'unit.conf',

  Optional[Rsyslog::Options]            $extra_global_params                                = undef,
  Optional[Rsyslog::Options]            $extra_legacy_globals                               = undef,
  Optional[Rsyslog::Options]            $extra_imfile_mod_params                            = undef,
  Optional[Rsyslog::Options]            $extra_imjournal_mod_params                         = undef,
  Optional[Rsyslog::Options]            $extra_imklog_mod_params                            = undef,
  Optional[Rsyslog::Options]            $extra_imptcp_mod_params                            = undef,
  Optional[Rsyslog::Options]            $extra_imtcp_mod_params                             = undef,
  Optional[Rsyslog::Options]            $extra_imudp_mod_params                             = undef,
  Optional[Rsyslog::Options]            $extra_imuxsock_mod_params                          = undef,
  Optional[Rsyslog::Options]            $extra_main_queue_params                            = undef
) {
  assert_private()

  if $default_template {
    warning('rsyslog::config::default_template is deprecated. Use rsyslog::config::default_file_template instead')
  }

  if $action_send_stream_driver_mode {
    warning('rsyslog::config::action_send_stream_driver_mode is deprecated. Use rsyslog::config::imtcp_stream_driver_mode instead')
  }

  if $action_send_stream_driver_auth_mode {
    warning('rsyslog::config::action_send_stream_driver_auth_mode is deprecated. Use rsyslog::config::imtcp_stream_driver_auth_mode instead')
  }

  if $suppress_noauth_warn !~ Undef {
    warning('rsyslog::config::suppress_noauth_warn is deprecated. Use rsyslog::config::net_permit_acl_warning instead')
  }

  if $disable_remote_dns !~ Undef {
    warning('rsyslog::config::disable_remote_dns is deprecated. Use rsyslog::config::net_enable_dns instead')
  }

  $_tcp_server = $rsyslog::tcp_server
  $_tls_tcp_server = $rsyslog::tls_tcp_server
  $_tcp_listen_port = $rsyslog::tcp_listen_port
  $_tls_tcp_listen_port = $rsyslog::tls_tcp_listen_port
  $_udp_server = $rsyslog::udp_server
  $_udp_listen_port = $rsyslog::udp_listen_port
  $_enable_tls_logging = $rsyslog::enable_tls_logging

  if $rsyslog::pki {
    simplib::assert_optional_dependency($module_name, 'simp/pki')

    pki::copy { 'rsyslog':
      source => $rsyslog::app_pki_external_source,
      pki    => $rsyslog::pki
    }
  }

  if $imtcp_stream_driver_auth_mode {
    $_imtcp_stream_driver_auth_mode = $imtcp_stream_driver_auth_mode
  }
  else {
    $_imtcp_stream_driver_auth_mode = $imtcp_stream_driver_mode ? {
      '0'     => 'anon',
      default => 'x509/name'
    }
  }


  #TODO drop this mapping, as it doesn't really help the end user
  $_default_file_template = $default_file_template ? {
    'traditional' => 'RSYSLOG_TraditionalFileFormat',
    'original'    => 'RSYSLOG_FileFormat',
    'forward'     => 'RSYSLOG_ForwardFormat',
    default       => $default_file_template
  }

  # This is where the custom rules will go. They will be purged if not managed!
  file { $rsyslog::rule_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    purge   => true,
    force   => true,
    mode    => '0750'
  }

  file { '/etc/rsyslog.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  $_readme = @(README)
    # In Puppet hieradata, set 'rsyslog::config::include_rsyslog_d' to true
    # and place ".conf" files that rsyslog should process independently of
    # SIMP into this directory.
    | README

  file { '/etc/rsyslog.d/README_SIMP.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $_readme
  }

  file { '/var/spool/rsyslog':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  if $enable_default_rules {
    rsyslog::rule { '99_simp_local/ZZ_default.conf':
      content => file("${module_name}/config/rsyslog.default")
    }
  }

  $_rsyslog_conf = @("RSYSLOG_CONF"/$)
    # This file is managed by Puppet (simp/rsyslog module).
    # Any changes will be overwritten.
    \$IncludeConfig ${rsyslog::rule_dir}/*.conf
    | RSYSLOG_CONF

  file { '/etc/rsyslog.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $_rsyslog_conf
  }

  $_sysconfig_rsyslog = @(SYSCONFIG_RSYSLOG)
    # This file is managed by Puppet (simp/rsyslog module).
    # Any changes will be overwritten.
    SYSLOGD_OPTIONS=""
    | SYSCONFIG_RSYSLOG

  file { '/etc/sysconfig/rsyslog':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $_sysconfig_rsyslog
  }

  rsyslog::rule { '00_simp_pre_logging/global.conf':
    content => template("${module_name}/config/pre_logging.conf.erb")
  }

  rsyslog::rule { '09_failover_hack/failover_hack.conf':
    # lint:ignore:variable_scope
    content => @(EOM)
      # For failover to be defined and parse properly, we must place it somewhere
      # after the first rule is defined. Therefore, we are creating this noop rule.

      if $syslogfacility == 'local0' and $msg startswith 'placeholder_rule' then continue
      |EOM
    # lint:endignore
  }

  if $include_rsyslog_d {
    rsyslog::rule { '15_include_default_rsyslog/include_default_rsyslog.conf':
      content => "\$IncludeConfig /etc/rsyslog.d/*.conf\n"
    }
  }

  # Set the maximum number of open files in the init script.
  init_ulimit { 'mod_open_files_rsyslog':
    target => 'rsyslog',
    item   => 'max_open_files',
    value  => $ulimit_max_open_files
  }

  if $facts['rsyslogd'] and ($facts['rsyslogd']['version'] == '8.24.0') {
    # This systemd override addresses a systemd service file bug present in the
    # rsyslog package included with CentOS 7.4.1708 (rsyslog-8.24.0-12.el7) and
    # fixed in the package included in CentOS 7.5 (rsyslog-8.24.0-16.el7).
    # Including this systemd override for 8.24.0 releases that already have the
    # fix will not cause problems, because the Wants and After lists are de-duped.
    $_override = @(OVERRIDE)
        # This file is managed by Puppet.

        [Unit]

        Wants=network.target network-online.target
        After=network.target network-online.target
        | OVERRIDE

    systemd::dropin_file { $systemd_override_file:
      unit    => 'rsyslog.service',
      content => $_override
    } ~> Class['rsyslog::service']
  }
}
