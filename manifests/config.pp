# @summary Setup Rsyslog configuration
#
# Every setting in this class is independently enforceable:
#
# * `undef` (the default) leaves the setting alone. Whatever an earlier run,
#   another tool or an administrator set stays.
# * A value sets it, replacing any earlier value.
# * `absent` removes it (`false` for `enable_default_rules`).
#
# With every parameter unset, this class declares no resources.
#
# Settings are written to files under `$rsyslog::rule_dir`
# (`00_simp_pre_logging/*.conf`). How rsyslog reads that directory depends on
# `$replace_rsyslog_conf`:
#
# * `false` (the default): a single `$IncludeConfig` line for
#   `$rsyslog::rule_dir` is added to the package's `/etc/rsyslog.conf`, after
#   its `/etc/rsyslog.d` include. Settings that the package's
#   `/etc/rsyslog.conf` already makes (`workDirectory`, the `imuxsock` and
#   `imjournal` modules and the `omfile` default template) cannot be set a
#   second time, so the parameters for them only warn in this mode. Set them
#   in `/etc/rsyslog.conf` directly, or set `$replace_rsyslog_conf`.
# * `true`: `/etc/rsyslog.conf` is replaced with one that includes only
#   `$rsyslog::rule_dir`, and the `imklog`, `imuxsock`, `imjournal` and
#   `imfile` modules are loaded from `00_simp_pre_logging`.
#
# **NOTE** Any undocumented parameters map directly to their counterparts in
# the Rsyslog configuration files.
#
# @param replace_rsyslog_conf
#   Replace `/etc/rsyslog.conf` with a file that includes only
#   `$rsyslog::rule_dir`
#
#   * **WARNING:** This discards the package's and any local configuration in
#     `/etc/rsyslog.conf`, including its default logging rules. Use
#     `$enable_default_rules` to restore SIMP's equivalent rules.
#
# @param purge_rule_dir
#   Remove every file under `$rsyslog::rule_dir` that Puppet does not manage
#
#   * **WARNING:** This is destructive. Rules that an earlier run, another
#     profile or an administrator placed there are deleted.
#
# @param syslogd_options
#   The value of `SYSLOGD_OPTIONS` in `/etc/sysconfig/rsyslog`
#
#   * `absent` removes the line.
#
# @param umask
#   The umask that should be applied to the running process
#
# @param localhostname
#   The Hostname that should be used on your syslog messages
#
#   * `auto` uses the node's FQDN.
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
#   * Only takes effect when `$replace_rsyslog_conf` is `true`.
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
#   * The `syssock_*` parameters only take effect when `$replace_rsyslog_conf`
#     is `true`.
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
#
# @param main_msg_queue_type
#   The type of queue that will be used
#
#   * It is **highly** recommended that you use ``LinkedList`` unless
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
#   * `auto` uses the minimum of 1% of physical memory or 1G, based on a 512B
#     message size.
#
# @param main_msg_queue_high_watermark
#   The point at which the main (global) message queue will start writing
#   messages to disk as a number of messages
#
#   * `auto` uses 90% of the main message queue size.
#
# @param main_msg_queue_low_watermark
#   The point at which the main (global) message queue will stop writing
#   messages to disk as a number of messages
#
#   * **NOTE:** This must be **lower** than ``$main_msg_queue_high_watermark``
#   * `auto` uses 70% of the main message queue size.
#
# @param main_msg_queue_discardmark
#   The point at which the main (global) message queue will discard messages
#
#   * `auto` uses 98% of the main message queue size.
#
# @param main_msg_queue_worker_thread_minimum_messages
#   The minimum number of messages in the main (global) message queue before
#   a new thread can be spawned
#
#   * `auto` uses ``main message queue size/(($processorcount - 1)*4)``
#
# @param main_msg_queue_worker_threads
#   The maximum number of main (global) message queue worker threads to spawn
#   on the system
#
#   * `auto` uses ``$processorcount - 1``
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
#  Whether data from the main (global) message queue should be saved at
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
#   * `auto` uses the main message queue size / 1024, in Megabytes.
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
#   * Only takes effect when `$replace_rsyslog_conf` is `true`, in which case
#     the directory is also managed.
#
# @param tls_tcp_max_sessions
#   The maximum number of sessions to support
#
#   * Only applies when `$rsyslog::tls_tcp_server` is `true`.
#
# @param tls_input_tcp_server_stream_driver_permitted_peers
#   A *wildcard-capable* Array of domains that should be allowed to talk to the
#   server over ``TLS``
#
#   * Only applies when `$rsyslog::tls_tcp_server` is `true`.
#   * When unset, `*.<the node's domain>` is written only if the setting is
#     missing, since the TLS listener rejects every peer without it.
#   * `auto` always writes `*.<the node's domain>`.
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
#   * When unset, `gtls` is written only if the setting is missing.
#   * `auto` always writes `gtls`.
#
# @param default_net_stream_driver_ca_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   defaultNetStreamDriverCAFile configuration parameter.
#
#   * When unset, `$rsyslog::app_pki_dir/cacerts/cacerts.pem` is written only
#     if the setting is missing.
#   * `auto` always writes `$rsyslog::app_pki_dir/cacerts/cacerts.pem`.
#
# @param default_net_stream_driver_cert_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   defaultNetStreamDriverCertFile configuration parameter.
#
#   * When unset, `$rsyslog::app_pki_dir/public/<fqdn>.pub` is written only if
#     the setting is missing.
#   * `auto` always writes `$rsyslog::app_pki_dir/public/<fqdn>.pub`.
#
# @param default_net_stream_driver_key_file
#   When ``TLS`` is enabled (client and/or server), used to set the global
#   defaultNetStreamDriverKeyFile configuration parameter.
#
#   * When unset, `$rsyslog::app_pki_dir/private/<fqdn>.pem` is written only
#     if the setting is missing.
#   * `auto` always writes `$rsyslog::app_pki_dir/private/<fqdn>.pem`.
#
# @param action_send_stream_driver_mode
#   **DEPRECATED** Use ``imtcp_stream_driver_mode.
#
# @param imtcp_stream_driver_mode
#   When ``$rsyslog::tls_tcp_server = true``, used to set the imtcp module's
#   default StreamDriver.Mode
#
#   * When unset, `1` is used when any of `$rsyslog::pki`,
#     `$rsyslog::tls_tcp_server` or `$rsyslog::enable_tls_logging` is set,
#     and `0` otherwise.
#
# @param action_send_stream_driver_auth_mode
#   **DEPRECATED** Use ``imtcp_stream_driver_auth_mode``.
#
# @param imtcp_stream_driver_auth_mode
#   When ``$rsyslog::tls_tcp_server = true``, used to set the imtcp module's
#   default StreamDriver.AuthMode.
#
#   * When unset, a value based on the stream driver mode (`anon` for `0`,
#     `x509/name` otherwise) is written only if the setting is missing.
#   * `auto` always writes that value.
#
# @param ulimit_max_open_files
#   The maximum open files limit that should be set for the syslog server
#
#   * ``1024`` is fine for most purposes, but a collection server should bump this
#     **way** up.
#   * Applied via a ``systemd`` drop-in file so that the shipped
#     ``rsyslog.service`` unit is not modified (preserves RPM integrity).
#   * `absent` removes the drop-in file.
#   * The legacy value ``'unlimited'`` is accepted for backwards
#     compatibility and translated to ``'infinity'`` (the systemd
#     spelling). A deprecation warning is emitted in that case.
#
# @param custom_conf_content
#   Optional content appended verbatim to ``/etc/rsyslog.conf`` after the
#   managed ``$IncludeConfig`` line.
#
#   * Only takes effect when `$replace_rsyslog_conf` is `true`.
#   * Intended for directives that must live in the main ``rsyslog.conf``
#     file itself (rather than in ``${rsyslog::rule_dir}``).
#   * No validation of the content is performed.
#
# @param enable_default_rules
#   Manage SIMP's default rules for logging common services (e.g., firewall,
#   puppet, slapd_auditd)
#
#   * `true` writes `99_simp_local/ZZ_default.conf`, and `false` removes it.
#   * These rules duplicate the package's `/etc/rsyslog.conf` rules, so use
#     them with `$replace_rsyslog_conf`.
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
#   * Only takes effect when `$replace_rsyslog_conf` is `true`, in which case
#     the `imjournal` module is loaded unless this is `false`.
#
# @param include_rsyslog_d
#   Include all configuration files in the system-standard ``/etc/rsyslog.d``
#
#   * Only takes effect when `$replace_rsyslog_conf` is `true`; the package's
#     `/etc/rsyslog.conf` already includes `/etc/rsyslog.d`.
#   * This will place the configuration files **after** the global
#     configuration but **before** the SIMP applied configurations.
#
# @param systemd_override_file
#   **DEPRECATED**. Has no effect. It named the systemd override file that
#   was only written for rsyslog 8.24.0 (EL7).
#
# @param extra_global_params
#   Additional global parameters, each written to its own
#   `00_simp_pre_logging/13_global_<name>.conf`
#
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_legacy_globals
#   Additional Legacy-style global parameters to be added to
#   00_simp_pre_logging/00_legacy.conf
#
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imfile_mod_params
#   Additional imfile module parameters to be added to the imfile load
#   statement in 00_simp_pre_logging/33_imfile.conf
#
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imjournal_mod_params
#   Additional imjournal module parameters to be added to the imjournal load
#   statement in 00_simp_pre_logging/32_imjournal.conf
#
#   * Only takes effect when `$replace_rsyslog_conf` is `true`.
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imklog_mod_params
#   Additional imklog module parameters to be added to the imklog load
#   statement in 00_simp_pre_logging/30_imklog.conf
#
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imptcp_mod_params
#   Additional imptcp module parameters to be added to the imptcp load
#   statement in 00_simp_pre_logging/40_imptcp.conf
#
#   * Only applies when $rsyslog::tls_tcp_server` is set to `true`
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imtcp_mod_params
#   Additional imtcp module parameters to be added to the imtcp load
#   statement in 00_simp_pre_logging/41_imtcp.conf
#
#   * Only applies when either $rsyslog::tcp_server` or
#     `$rsyslog::tls_tcp_server` is set to `true`
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imudp_mod_params
#   Additional imudp module parameters to be added to the imudp load
#   statement in 00_simp_pre_logging/42_imudp.conf
#
#   * Only applies when `$rsyslog::udp_server` is set to `true`
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_imuxsock_mod_params
#   Additional imuxsock module parameters to be added to the imuxsock load
#   statement in 00_simp_pre_logging/31_imuxsock.conf
#
#   * Only takes effect when `$replace_rsyslog_conf` is `true`.
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @param extra_main_queue_params
#   Additional main queue parameters to be added to the main_queue
#   configuration statement in 00_simp_pre_logging/90_main_queue.conf
#
#   * A value of `absent` removes the parameter.
#   * No validation of parameter names or values is done
#
# @api private
class rsyslog::config (
  Boolean                                                     $replace_rsyslog_conf                               = false,
  Boolean                                                     $purge_rule_dir                                     = false,
  Optional[String]                                            $syslogd_options                                    = undef,

  Optional[Variant[Simplib::Umask, Enum['absent']]]           $umask                                              = undef,
  Optional[String[1]]                                         $localhostname                                      = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $preserve_fqdn                                      = undef,
  Optional[Variant[String[1,1], Enum['absent']]]              $control_character_escape_prefix                    = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $drop_msgs_with_malicious_dns_ptr_records           = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $escape_control_characters_on_receive               = undef,
  Optional[String]                                            $default_template                                   = undef,
  Optional[String[1]]                                         $default_file_template                              = undef,
  Optional[String[1]]                                         $default_forward_template                           = undef,

  # Parameters for imuxsock
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_ignore_timestamp                           = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_ignore_own_messages                        = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_use                                        = undef,
  Optional[String[1]]                                         $syssock_name                                       = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_flow_control                               = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_use_pid_from_system                        = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $syssock_rate_limit_interval                        = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $syssock_rate_limit_burst                           = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $syssock_rate_limit_severity                        = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_use_sys_timestamp                          = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_annotate                                   = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_parse_trusted                              = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $syssock_unlink                                     = undef,

  # Main message queue
  Optional[Variant[Rsyslog::QueueType, Enum['absent']]]       $main_msg_queue_type                                = undef,
  Optional[String[1]]                                         $main_msg_queue_filename                            = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $main_msg_queue_max_file_size                       = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_size                                = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_high_watermark                      = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_low_watermark                       = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_discardmark                         = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_worker_thread_minimum_messages      = undef,
  Optional[Variant[Integer[0], Enum['auto', 'absent']]]       $main_msg_queue_worker_threads                      = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $main_msg_queue_timeout_enqueue                     = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $main_msg_queue_dequeue_slowdown                    = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $main_msg_queue_save_on_shutdown                    = undef,
  Optional[Variant[Integer[0], String[1]]]                    $main_msg_queue_max_disk_space                      = undef,

  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $repeated_msg_reduction                             = undef,
  Optional[Variant[Stdlib::Absolutepath, Enum['absent']]]     $work_directory                                     = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $tls_tcp_max_sessions                               = undef,
  Optional[Variant[Array[String[1]], Enum['auto', 'absent']]] $tls_input_tcp_server_stream_driver_permitted_peers = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $keep_alive                                         = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $keep_alive_probes                                  = undef,
  Optional[Variant[Integer[0], Enum['absent']]]               $keep_alive_time                                    = undef,

  Optional[Enum['gtls', 'ptcp', 'auto', 'absent']]            $default_net_stream_driver                          = undef,
  Optional[Variant[Stdlib::Absolutepath, Enum['auto', 'absent']]] $default_net_stream_driver_ca_file              = undef,
  Optional[Variant[Stdlib::Absolutepath, Enum['auto', 'absent']]] $default_net_stream_driver_cert_file            = undef,
  Optional[Variant[Stdlib::Absolutepath, Enum['auto', 'absent']]] $default_net_stream_driver_key_file             = undef,

  Optional[Enum['1','0']]                                     $action_send_stream_driver_mode                     = undef,
  Optional[Enum['1','0']]                                     $imtcp_stream_driver_mode                           = undef,
  Optional[String]                                            $action_send_stream_driver_auth_mode                = undef,
  Optional[String[1]]                                         $imtcp_stream_driver_auth_mode                      = undef,

  Optional[Variant[Enum['infinity','unlimited','absent'],Integer[0]]] $ulimit_max_open_files                      = undef,
  Optional[String[1]]                                         $custom_conf_content                                = undef,
  Optional[Boolean]                                           $enable_default_rules                               = undef,
  Optional[Boolean]                                           $suppress_noauth_warn                               = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $net_permit_acl_warning                             = undef,
  Optional[Boolean]                                           $disable_remote_dns                                 = undef,
  Optional[Variant[Rsyslog::Boolean, Enum['absent']]]         $net_enable_dns                                     = undef,

  Optional[Boolean]                                           $read_journald                                      = $rsyslog::read_journald,
  Optional[Boolean]                                           $include_rsyslog_d                                  = undef,
  Optional[String]                                            $systemd_override_file                              = undef,

  Optional[Rsyslog::Options]                                  $extra_global_params                                = undef,
  Optional[Rsyslog::Options]                                  $extra_legacy_globals                               = undef,
  Optional[Rsyslog::Options]                                  $extra_imfile_mod_params                            = undef,
  Optional[Rsyslog::Options]                                  $extra_imjournal_mod_params                         = undef,
  Optional[Rsyslog::Options]                                  $extra_imklog_mod_params                            = undef,
  Optional[Rsyslog::Options]                                  $extra_imptcp_mod_params                            = undef,
  Optional[Rsyslog::Options]                                  $extra_imtcp_mod_params                             = undef,
  Optional[Rsyslog::Options]                                  $extra_imudp_mod_params                             = undef,
  Optional[Rsyslog::Options]                                  $extra_imuxsock_mod_params                          = undef,
  Optional[Rsyslog::Options]                                  $extra_main_queue_params                            = undef,
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

  if $systemd_override_file !~ Undef {
    deprecation('rsyslog::config::systemd_override_file',
      'rsyslog::config::systemd_override_file is deprecated and has no effect. It was only used for rsyslog 8.24.0 (EL7)', false)
  }

  if $ulimit_max_open_files == 'unlimited' {
    warning("rsyslog::config::ulimit_max_open_files value 'unlimited' is deprecated. Use 'infinity' instead.")
    $_ulimit_max_open_files = 'infinity'
  }
  else {
    $_ulimit_max_open_files = $ulimit_max_open_files
  }

  $_tls_tcp_server = $rsyslog::tls_tcp_server
  $_tcp_server = $rsyslog::tcp_server
  $_udp_server = $rsyslog::udp_server

  if $rsyslog::rule_dir =~ /hostname/ {
    warning("rsyslog::rule_dir '${rsyslog::rule_dir}' contains 'hostname'. SELinux labels files under such a path hostname_etc_t, which rsyslog cannot read on EL10.")
  }

  # Whether /etc/rsyslog.conf is this module's: replaced in this run, or
  # written by an earlier run or an earlier version of the module. It then
  # includes only the rule directory, so the module loads rsyslog's inputs.
  $_conf_managed = $facts.dig('rsyslog_simp_config', 'conf_managed') == true
  $simp_conf = $replace_rsyslog_conf or $_conf_managed

  # Settings that the package's /etc/rsyslog.conf already makes. Rsyslog
  # rejects a second value for them, so they can only be set when
  # /etc/rsyslog.conf is this module's.
  $_package_conf_settings = {
    'default_file_template'       => $default_file_template,
    'work_directory'              => $work_directory,
    'syssock_ignore_timestamp'    => $syssock_ignore_timestamp,
    'syssock_ignore_own_messages' => $syssock_ignore_own_messages,
    'syssock_use'                 => $syssock_use,
    'syssock_name'                => $syssock_name,
    'syssock_flow_control'        => $syssock_flow_control,
    'syssock_use_pid_from_system' => $syssock_use_pid_from_system,
    'syssock_rate_limit_interval' => $syssock_rate_limit_interval,
    'syssock_rate_limit_burst'    => $syssock_rate_limit_burst,
    'syssock_rate_limit_severity' => $syssock_rate_limit_severity,
    'syssock_use_sys_timestamp'   => $syssock_use_sys_timestamp,
    'syssock_annotate'            => $syssock_annotate,
    'syssock_parse_trusted'       => $syssock_parse_trusted,
    'syssock_unlink'              => $syssock_unlink,
    'read_journald'               => $read_journald,
    'extra_imuxsock_mod_params'   => $extra_imuxsock_mod_params,
    'extra_imjournal_mod_params'  => $extra_imjournal_mod_params,
    'include_rsyslog_d'           => $include_rsyslog_d ? { true => true, default => undef },
  }

  unless $simp_conf {
    $_package_conf_settings.each |$setting, $value| {
      if $value =~ NotUndef {
        warning("rsyslog::config::${setting} has no effect unless rsyslog::config::replace_rsyslog_conf is true, because the package's /etc/rsyslog.conf already sets it. Set it in /etc/rsyslog.conf instead.")
      }
    }
  }

  if $custom_conf_content =~ NotUndef and !$replace_rsyslog_conf {
    warning('rsyslog::config::custom_conf_content has no effect unless rsyslog::config::replace_rsyslog_conf is true')
  }

  if $rsyslog::pki {
    simplib::assert_optional_dependency($module_name, 'simp/pki')

    pki::copy { 'rsyslog':
      source => $rsyslog::app_pki_external_source,
      pki    => $rsyslog::pki
    }
  }

  ##############################################################################
  # /etc/rsyslog.conf and the rule directory
  ##############################################################################

  if $replace_rsyslog_conf {
    include 'rsyslog::config::rule_tree'
    include 'rsyslog::config::failover_hack'

    $_readme = @(README)
      # In Puppet hieradata, set 'rsyslog::config::include_rsyslog_d' to true
      # and place ".conf" files that rsyslog should process independently of
      # SIMP into this directory.
      | README

    file { '/etc/rsyslog.d/README_SIMP.conf':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $_readme,
      require => Class['rsyslog::install'],
    }

    # The modules a replaced rsyslog.conf needs
    include 'rsyslog::config::pre_logging'
  }
  elsif $purge_rule_dir {
    include 'rsyslog::config::rule_tree'

    # The purge removes the global.conf of earlier versions, which loaded the
    # inputs a module-owned rsyslog.conf needs
    if $simp_conf {
      include 'rsyslog::config::pre_logging'
    }
  }

  # The package's /etc/rsyslog.conf already includes /etc/rsyslog.d
  if $include_rsyslog_d == false or ($include_rsyslog_d and $simp_conf) {
    rsyslog::rule { '15_include_default_rsyslog/include_default_rsyslog.conf':
      ensure  => bool2str($include_rsyslog_d, 'present', 'absent'),
      content => "\$IncludeConfig /etc/rsyslog.d/*.conf\n",
    }
  }

  # rsyslog does not start without any action. When this run replaces the
  # package's rsyslog.conf (and with it the package's rules), or purges the
  # rule directory of a module-owned rsyslog.conf, write SIMP's default rules
  # if they are missing.
  $_seed_default_rules = $simp_conf and ($purge_rule_dir or !$_conf_managed)

  if $enable_default_rules =~ Boolean or $_seed_default_rules {
    if $enable_default_rules and !$simp_conf {
      warning('rsyslog::config::enable_default_rules duplicates the rules in the package\'s /etc/rsyslog.conf unless rsyslog::config::replace_rsyslog_conf is true')
    }

    rsyslog::rule { '99_simp_local/ZZ_default.conf':
      ensure  => bool2str($enable_default_rules == false, 'absent', 'present'),
      content => file("${module_name}/config/rsyslog.default"),
      replace => $enable_default_rules =~ Boolean,
    }
  }

  if $syslogd_options =~ NotUndef {
    rsyslog::config::line { 'sysconfig SYSLOGD_OPTIONS':
      ensure => bool2str($syslogd_options == 'absent', 'absent', 'present'),
      path   => '/etc/sysconfig/rsyslog',
      line   => "SYSLOGD_OPTIONS=\"${syslogd_options}\"",
      match  => '^\s*SYSLOGD_OPTIONS=',
    }
  }

  ##############################################################################
  # 00_simp_pre_logging: legacy globals
  ##############################################################################

  $_legacy = {
    'UMASK'                => $umask,
    'RepeatedMsgReduction' => $repeated_msg_reduction,
  } + pick($extra_legacy_globals, {})

  $_legacy_set = $_legacy.filter |$k, $v| { $v =~ NotUndef }

  unless empty($_legacy_set) {
    rsyslog::config::block { '00_legacy':
      seed => '',
    }

    $_legacy_set.each |$name, $value| {
      rsyslog::config::line { "00_legacy ${name}":
        ensure  => bool2str($value == 'absent', 'absent', 'present'),
        path    => "${rsyslog::rule_dir}/00_simp_pre_logging/00_legacy.conf",
        line    => "\$${name} ${rsyslog::format_value($value)}",
        match   => "^\\\$${regexpescape($name)}\\s",
        require => Rsyslog::Config::Block['00_legacy'],
      }
    }
  }

  ##############################################################################
  # 00_simp_pre_logging: global() settings
  #
  # WARNING: global() does not always behave as expected!
  # There is some internal rsyslog behavior WRT the settings that dictates
  # whether specific settings actually take effect. Ordering and grouping make
  # a difference.  Had to empirically play around with ordering and grouping
  # to get the globals we configure to work:
  #
  # - localHostname did not work when included in the first global(). Didn't
  #   matter whether it was first in the list or last in the list.
  # - defaultNetstreamDriver* globals did not work when included in the first
  #   global().
  ##############################################################################

  $_work_directory = $simp_conf ? {
    true    => $work_directory,
    default => undef,
  }

  if $_work_directory =~ Stdlib::Absolutepath {
    file { $_work_directory:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => Class['rsyslog::install'],
    }
  }

  $_global = {
    'preserveFQDN'                            => $preserve_fqdn,
    'dropMsgsWithMaliciousDnsPTRRecords'      => $drop_msgs_with_malicious_dns_ptr_records,
    'workDirectory'                           => $_work_directory,
    'net.permitACLWarning'                    => $net_permit_acl_warning,
    'net.enableDNS'                           => $net_enable_dns,
    'parser.escapeControlCharactersOnReceive' => $escape_control_characters_on_receive,
    'parser.controlCharacterEscapePrefix'     => $control_character_escape_prefix,
  }.filter |$k, $v| { $v =~ NotUndef }

  unless empty($_global) {
    rsyslog::config::statement { '10_global':
      header => 'global(',
      params => $_global,
    }
  }

  if $localhostname =~ NotUndef {
    $_localhostname = $localhostname ? {
      'auto'  => $facts['networking']['fqdn'],
      default => $localhostname,
    }

    # The file name must not contain 'hostname': the SELinux policy labels
    # /etc/.*hostname.* as hostname_etc_t, which rsyslog cannot read on EL10.
    rsyslog::rule { '00_simp_pre_logging/11_global_localhost_name.conf':
      ensure  => bool2str($localhostname == 'absent', 'absent', 'present'),
      content => "global(localHostname=\"${_localhostname}\")\n",
    }
  }

  if $rsyslog::enable_tls_logging or $_tls_tcp_server {
    include 'rsyslog::config::tls'
  }

  pick($extra_global_params, {}).each |$name, $value| {
    rsyslog::rule { "00_simp_pre_logging/13_global_${name}.conf":
      ensure  => bool2str($value == 'absent', 'absent', 'present'),
      content => "global(${name}=\"${value}\")\n",
    }
  }

  ##############################################################################
  # 00_simp_pre_logging: output and input modules
  ##############################################################################

  if $simp_conf and $default_file_template =~ NotUndef {
    $_default_file_template = $default_file_template ? {
      'traditional' => 'RSYSLOG_TraditionalFileFormat',
      'original'    => 'RSYSLOG_FileFormat',
      'forward'     => 'RSYSLOG_ForwardFormat',
      default       => $default_file_template
    }

    rsyslog::rule { '00_simp_pre_logging/20_omfile.conf':
      ensure  => bool2str($default_file_template == 'absent', 'absent', 'present'),
      content => "module(load=\"builtin:omfile\" template=\"${_default_file_template}\")\n",
    }
  }

  if $default_forward_template =~ NotUndef {
    rsyslog::rule { '00_simp_pre_logging/21_omfwd.conf':
      ensure  => bool2str($default_forward_template == 'absent', 'absent', 'present'),
      content => "module(load=\"builtin:omfwd\" template=\"${default_forward_template}\")\n",
    }
  }

  # imklog, imuxsock, imjournal and imfile
  if $extra_imklog_mod_params =~ NotUndef or $extra_imfile_mod_params =~ NotUndef or
  ($simp_conf and !empty($_package_conf_settings.filter |$k, $v| { $v =~ NotUndef })) {
    include 'rsyslog::config::pre_logging'
  }

  ##############################################################################
  # 00_simp_pre_logging: listeners
  #
  # * tls_tcp_server: a plain imptcp listener on tcp_listen_port, plus a TLS
  #   imtcp listener on tls_tcp_listen_port
  # * tcp_server (without tls_tcp_server): a plain imtcp listener on
  #   tcp_listen_port
  # * udp_server: an imudp listener on udp_listen_address:udp_listen_port
  #
  # `false` removes a listener and undef leaves it alone. The TLS and plain
  # imtcp listeners share 41_imtcp.conf (rsyslog loads imtcp once), so turning
  # one off removes its input and settings and leaves the other's.
  ##############################################################################

  $_pre_logging = "${rsyslog::rule_dir}/00_simp_pre_logging"
  $_imtcp_exists = '41_imtcp.conf' in rsyslog::existing_pre_logging()
  $_tls_off = {
    'StreamDriver.Mode'     => 'absent',
    'StreamDriver.AuthMode' => 'absent',
    'PermittedPeer'         => 'absent',
    'MaxSessions'           => 'absent',
  }

  if $_tls_tcp_server {
    rsyslog::config::statement { '40_imptcp':
      header => 'module(load="imptcp"',
      params => pick($extra_imptcp_mod_params, {}),
      create => true,
    }

    rsyslog::config::line { '40_imptcp input':
      path    => "${_pre_logging}/40_imptcp.conf",
      line    => "input(type=\"imptcp\" port=\"${rsyslog::tcp_listen_port}\")",
      match   => '^\s*input\(type="imptcp"',
      require => Rsyslog::Config::Block['40_imptcp'],
    }
  }
  elsif $_tls_tcp_server == false {
    rsyslog::config::statement { '40_imptcp':
      ensure => 'absent',
      header => 'module(load="imptcp"',
    }
  }

  if $_tls_tcp_server or $_tcp_server {
    $_imtcp_stream_driver_mode = pick(
      $imtcp_stream_driver_mode,
      ($rsyslog::pki or $_tls_tcp_server or $rsyslog::enable_tls_logging) ? { true => '1', default => '0' }
    )

    $_derived_auth_mode = $_imtcp_stream_driver_mode ? {
      '0'     => 'anon',
      default => 'x509/name'
    }

    $_permitted_peers = ["*.${facts['networking']['domain']}"]

    if $_tls_tcp_server {
      $_tls_params = {
        'StreamDriver.Mode'     => $_imtcp_stream_driver_mode,
        'StreamDriver.AuthMode' => $imtcp_stream_driver_auth_mode ? {
          'auto'  => $_derived_auth_mode,
          default => $imtcp_stream_driver_auth_mode,
        },
        'PermittedPeer'         => $tls_input_tcp_server_stream_driver_permitted_peers ? {
          'auto'  => $_permitted_peers,
          default => $tls_input_tcp_server_stream_driver_permitted_peers,
        },
        'MaxSessions'           => $tls_tcp_max_sessions,
      }

      # The TLS listener cannot work without these.
      $_tls_fallbacks = {
        'StreamDriver.AuthMode' => $_derived_auth_mode,
        'PermittedPeer'         => $_permitted_peers,
      }

      $_imtcp_port = $rsyslog::tls_tcp_listen_port
    }
    else {
      $_tls_params = $_tls_tcp_server ? {
        false   => $_tls_off,
        default => {},
      }

      $_tls_fallbacks = {}
      $_imtcp_port = $rsyslog::tcp_listen_port
    }

    rsyslog::config::statement { '41_imtcp':
      header    => 'module(load="imtcp"',
      params    => $_tls_params + {
        'KeepAlive'       => $keep_alive,
        'KeepAliveProbes' => $keep_alive_probes,
        'KeepAliveTime'   => $keep_alive_time,
      } + pick($extra_imtcp_mod_params, {}),
      fallbacks => $_tls_fallbacks,
      create    => true,
    }

    rsyslog::config::line { '41_imtcp input':
      path    => "${_pre_logging}/41_imtcp.conf",
      line    => "input(type=\"imtcp\" port=\"${_imtcp_port}\")",
      match   => '^\s*input\(type="imtcp"',
      require => Rsyslog::Config::Block['41_imtcp'],
    }
  }
  elsif $_tls_tcp_server == false and $_tcp_server == false {
    rsyslog::config::statement { '41_imtcp':
      ensure => 'absent',
      header => 'module(load="imtcp"',
    }
  }
  elsif $_imtcp_exists and ($_tls_tcp_server == false or $_tcp_server == false) {
    # Remove one listener and leave the other's
    if $_tls_tcp_server == false {
      $_off_params = $_tls_off
      $_off_port = $rsyslog::tls_tcp_listen_port
    }
    else {
      $_off_params = {}
      $_off_port = $rsyslog::tcp_listen_port
    }

    rsyslog::config::statement { '41_imtcp':
      header => 'module(load="imtcp"',
      params => $_off_params,
    }

    rsyslog::config::line { '41_imtcp input':
      ensure => 'absent',
      path   => "${_pre_logging}/41_imtcp.conf",
      line   => "input(type=\"imtcp\" port=\"${_off_port}\")",
      match  => "^\\s*input\\(type=\"imtcp\" port=\"${_off_port}\"\\)",
    }
  }

  if $_udp_server {
    rsyslog::config::statement { '42_imudp':
      header => 'module(load="imudp"',
      params => pick($extra_imudp_mod_params, {}),
      create => true,
    }

    rsyslog::config::line { '42_imudp input':
      path    => "${_pre_logging}/42_imudp.conf",
      line    => "input(type=\"imudp\" address=\"${rsyslog::udp_listen_address}\" port=\"${rsyslog::udp_listen_port}\")",
      match   => '^\s*input\(type="imudp"',
      require => Rsyslog::Config::Block['42_imudp'],
    }
  }
  elsif $_udp_server == false {
    rsyslog::config::statement { '42_imudp':
      ensure => 'absent',
      header => 'module(load="imudp"',
    }
  }

  ##############################################################################
  # 00_simp_pre_logging: main_queue()
  ##############################################################################

  $_memory_mb = pick($facts.dig('memory', 'system', 'total_bytes'), 0) >> 20
  $_processors = pick($facts.dig('processors', 'count'), 1)

  $_auto_queue_size = [Integer(([$_memory_mb, 128].max() * 2048) / 100), 2097152].min()
  $_queue_size = $main_msg_queue_size ? {
    Integer => $main_msg_queue_size,
    default => $_auto_queue_size,
  }

  $_auto_queue = {
    'size'                        => $_queue_size,
    'highwatermark'               => round($_queue_size * 0.9),
    'lowwatermark'                => round($_queue_size * 0.7),
    'discardmark'                 => round($_queue_size * 0.98),
    'workerthreadminimummessages' => Integer($_queue_size / (([$_processors, 2].max() - 1) * 4)),
    'workerthreads'               => [$_processors - 1, 1].max(),
    'maxdiskspace'                => "${round($_queue_size / 1024)}M",
  }

  $_main_queue = {
    'type'                        => $main_msg_queue_type,
    'filename'                    => $main_msg_queue_filename,
    'maxfilesize'                 => $main_msg_queue_max_file_size ? {
      Integer => "${main_msg_queue_max_file_size}M",
      default => $main_msg_queue_max_file_size,
    },
    'size'                        => $main_msg_queue_size,
    'highwatermark'               => $main_msg_queue_high_watermark,
    'lowwatermark'                => $main_msg_queue_low_watermark,
    'discardmark'                 => $main_msg_queue_discardmark,
    'workerthreadminimummessages' => $main_msg_queue_worker_thread_minimum_messages,
    'workerthreads'               => $main_msg_queue_worker_threads,
    'timeoutenqueue'              => $main_msg_queue_timeout_enqueue,
    'dequeueslowdown'             => $main_msg_queue_dequeue_slowdown,
    'saveonshutdown'              => $main_msg_queue_save_on_shutdown,
    'maxdiskspace'                => $main_msg_queue_max_disk_space,
  }.reduce({}) |$memo, $kv| {
    $memo + {
      "queue.${kv[0]}" => $kv[1] ? {
        'auto'  => $_auto_queue[$kv[0]],
        default => $kv[1],
      },
    }
  }

  $_main_queue_set = ($_main_queue + pick($extra_main_queue_params, {})).filter |$k, $v| { $v =~ NotUndef }

  unless empty($_main_queue_set) {
    rsyslog::config::statement { '90_main_queue':
      header => 'main_queue(',
      params => $_main_queue_set,
    }
  }

  ##############################################################################
  # systemd
  ##############################################################################

  if $_ulimit_max_open_files =~ NotUndef {
    # Set the maximum number of open files via a systemd drop-in so that the
    # shipped /usr/lib/systemd/system/rsyslog.service unit is not modified.
    # Modifying the shipped unit causes RPM hash mismatches.
    $_limits_dropin = @("LIMITS"/$)
      # This file is managed by Puppet (simp/rsyslog module).
      # Any changes will be overwritten.
      [Service]
      LimitNOFILE=${_ulimit_max_open_files}
      | LIMITS

    systemd::dropin_file { 'simp_limits.conf':
      ensure  => bool2str($_ulimit_max_open_files == 'absent', 'absent', 'present'),
      unit    => 'rsyslog.service',
      content => $_limits_dropin,
    } ~> Class['rsyslog::service']
  }
}
