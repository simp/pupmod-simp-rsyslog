# Adds a rule to send messages to a remote system
#
# In general, the order will be:
#
#   * Data Source Rules
#   * Console Rules
#   * Drop Rules
#   * Remote Rules
#   * Other/Miscellaneous Rules
#   * Local Rules
#
# If you wish to use TLS for forward RSyslog messages, you **MUST** configre it
# via ``rsyslog::config``. Current EL versions of RSyslog 7 do not properly
# support individual TLS settings via rulesets.
#
# ------------------------------------------------------------------------
#
# > **WARNING**
# >
# > If possible, this module will take pains to prevent adding a target that is
# > equivalent to the current system to prevent syslog loops.
# >
# > Unfortunately, there is **no** foolproof method for getting this correct
# > 100% of the time so please take care when setting your destination targets.
# >
# > **WARNING**
#
# ------------------------------------------------------------------------
#
# @example Send All ``local0`` Messages to ``1.2.3.4`` via TCP
#   rsyslog::rule::other { 'send_local0_away':
#     rule        => "prifilt('local0.*')",
#     log_servers => ['1.2.3.4']
#   }
#
# @param name [Stdlib::Absolutepath]
#   The filename that you will be dropping into place
#
# @param rule
#   The Rsyslog ``EXPRESSION`` to filter on
#
#   * This should only be the matching part of the expression, the remaining
#     parameters take care of ensuring that the material is properly routed.
#
#   * **NOTE:** Do **NOT** include the leading ``if/then``
#       * Correct:   ``rule => "prifilt('*.*')"
#       * Incorrect: ``rule => "if prifilt('*.*') then"``
#
# @param template
#   The template that should be used to format the content
#
# @param dest
#   If filled, the ``$content`` will be sent to **all hosts** in this Array.
#
#   * **WARNING:** If using this, do **NOT** add a destination to your ``rule``
#
# @param dest_type
#   The destination type for all entries in ``$dest``
#
#   * At this time, if you wish to have different types per destination, you
#     will need to craft your own ruleset and leave ``$dest`` empty.
#
# @param failover_log_servers
#   The listed systems will be used as failover servers for all logs matching
#   this ``rule``
#
#   * Uses ``$dest_type`` above
#
# @param tcp_framing
# @param zip_level
# @param max_error_messages
# @param compression_mode
# @param compression_stream_flush_on_tx_end
# @param rebind_interval
# @param action_resume_interval
# @param action_resume_retry_count
#
# @param stream_driver
#   This is overridden by the ``rsyslog::config::default_net_stream_driver``
#
#   * EL versions of Rsyslog 7 do not support this properly in rulesets but it
#     may be specified
#
# @param stream_driver_mode
#   This is overridden by the ``rsyslog::config::action_send_stream_driver_mode``
#
#   * EL versions of Rsyslog 7 do not support this properly in rulesets but it
#     may be specified
#
# @param stream_driver_auth_mode
#   This is overridden by the ``rsyslog::config::action_send_stream_driver_auth_mode``
#
#   * EL versions of Rsyslog 7 partially support this in rulesets and it may
#     have some effect
#
# @param stream_driver_permitted_peers
#   This is overridden by the ``rsyslog::config::action_send_stream_driver_permitted_peers``
#
#   * EL versions of Rsyslog 7 partially support this in rulesets and it may
#     have some effect
#
# @param resend_last_msg_on_reconnect
# @param udp_send_to_all
# @param queue_filename
# @param queue_spool_directory
# @param queue_size
# @param queue_dequeue_batch_size
# @param queue_max_disk_space
# @param queue_high_watermark
# @param queue_low_watermark
# @param queue_full_delay_mark
# @param queue_light_delay_mark
# @param queue_discard_mark
# @param queue_discard_severity
# @param queue_checkpoint_interval
# @param queue_sync_queue_files
# @param queue_type
# @param queue_worker_threads
# @param queue_timeout_shutdown
# @param queue_timeout_action_completion
# @param queue_timeout_enqueue
# @param queue_timeout_worker_thread_shutdown
# @param queue_worker_thread_minimum_messages
# @param queue_max_file_size
# @param queue_save_on_shutdown
# @param queue_dequeue_slowdown
# @param queue_dequeue_time_begin
# @param queue_dequeue_time_end
#
# @see https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see http://www.rsyslog.com/doc/expression.html Expressions in Rsyslog
#
# @see http://www.rsyslog.com/doc/rainerscript.html RainerScript Documentation
#
define rsyslog::rule::remote (
  String                                           $rule,
  Boolean                                          $stop_processing                      = false,
  Optional[String]                                 $template                             = undef,
  Simplib::Netlist                                 $dest                                 = [],
  Enum['tcp','udp','relp']                         $dest_type                            = 'tcp',
  Simplib::Netlist                                 $failover_log_servers                 = [],
  Enum['traditional','octet-counted']              $tcp_framing                          = 'traditional',
  Integer[0,9]                                     $zip_level                            = 0,
  Integer[0]                                       $max_error_messages                   = 5,
  Enum['none','single','stream:always']            $compression_mode                     = 'none',
  Boolean                                          $compression_stream_flush_on_tx_end   = true,
  Optional[Integer[0]]                             $rebind_interval                      = undef,
  Integer[0]                                       $action_resume_interval               = 30,
  Integer[-1]                                      $action_resume_retry_count            = -1,
  Optional[String]                                 $stream_driver                        = undef,
  Integer[0]                                       $stream_driver_mode                   = 1,
  String                                           $stream_driver_auth_mode              = 'x509/name',
  String                                           $stream_driver_permitted_peers        = "*.${::domain}",
  Boolean                                          $resend_last_msg_on_reconnect         = true,
  Boolean                                          $udp_send_to_all                      = false,
  Optional[String]                                 $queue_filename                       = undef,
  Optional[Stdlib::Absolutepath]                   $queue_spool_directory                = undef,
  Optional[Integer[0]]                             $queue_size                           = undef,
  Integer[0]                                       $queue_dequeue_batch_size             = 16,
  Optional[Integer[0]]                             $queue_max_disk_space                 = undef,
  Optional[Integer[0]]                             $queue_high_watermark                 = undef,
  Integer[0]                                       $queue_low_watermark                  = 2000,
  Optional[Integer[0]]                             $queue_full_delay_mark                = undef,
  Optional[Integer[0]]                             $queue_light_delay_mark               = undef,
  Integer[0]                                       $queue_discard_mark                   = 9750,
  Integer[0]                                       $queue_discard_severity               = 8,
  Optional[Integer[0]]                             $queue_checkpoint_interval            = undef,
  Boolean                                          $queue_sync_queue_files               = false,
  Enum['LinkedList','FixedArray','Direct','Disk']  $queue_type                           = 'LinkedList',
  Integer[0]                                       $queue_worker_threads                 = 1,
  Integer[0]                                       $queue_timeout_shutdown               = 0,
  Integer[0]                                       $queue_timeout_action_completion      = 1000,
  Integer[0]                                       $queue_timeout_enqueue                = 2000,
  Integer[0]                                       $queue_timeout_worker_thread_shutdown = 60000,
  Integer[0]                                       $queue_worker_thread_minimum_messages = 100,
  String                                           $queue_max_file_size                  = '1m',
  Boolean                                          $queue_save_on_shutdown               = true,
  Integer[0]                                       $queue_dequeue_slowdown               = 0,
  Optional[Integer[0]]                             $queue_dequeue_time_begin             = undef,
  Optional[Integer[0]]                             $queue_dequeue_time_end               = undef
) {
  include '::rsyslog'

  if empty($dest) {
    $_dest = $::rsyslog::log_servers
  }
  else {
    $_dest = $dest
  }

  if empty($_dest) { fail('You must pass a destination array for $dest') }

  if $queue_spool_directory {
    $_queue_spool_directory = $queue_spool_directory
  }
  else {
    $_queue_spool_directory = $::rsyslog::queue_spool_directory
  }

  $_use_tls = ( $::rsyslog::enable_tls_logging and $dest_type != 'udp' )

  if empty($failover_log_servers) {
    $_failover_servers = $::rsyslog::failover_log_servers
  }
  else {
    $_failover_servers = $failover_log_servers
  }

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "10_simp_remote/${_safe_name}.conf":
    content => template("${module_name}/rule/remote.erb")
  }
}
