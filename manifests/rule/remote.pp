# Adds a rule to send messages to one or more remote system.
# The rule will include a forwarding ('omfwd') action for each
# primary and failover syslog server specified via ``$dest`` and
# ``$failover_log_servers``, respectively.
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
# In general, individual send stream driver settings are properly supported
# with the Rsyslog 8 EL versions available for CentOS 7 and the Rsyslog 7
# EL versions available for CentOS 6. However, for TLS support, you must
# also configure global Rsyslog parameters as follows:
#
# * TLS sending and/or receiving requires the global DefaultNetStreamDriver,
#   DefaultNetStreamDriverCAFile, DefaultNetStreamDriverCertFile, and
#   DefaultNetStreamDriverKeyFile parameters to be configure via
#   ``rsyslog::config``.
#
# * TLS sending for Rsyslog 7 EL versions requires the global
#   ActionSendStreamDriverMode configuration parameter to be configured via
#   ``rsyslog::config`` **IN ADDITION TO** the ``$stream_driver_mode``.
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
#   rsyslog::rule::remote { 'send_local0_away':
#     rule => "prifilt('local0.*')",
#     dest => ['1.2.3.4']
#   }
#
# @param name [String]
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
#  * This **must** be set if ``$content`` is left empty
#
# @param stop_processing
#   Do not forward logs to any further ``ruleset``s after processing this ``ruleset``
#
# @param template
#   The template that should be used to format the content
#
# @param dest
#   If filled, logs matching ``$rule`` will be sent to **all hosts** in this Array.
#
#   * **WARNING:** If using this, do **NOT** add a destination to your ``rule``
#
# @param dest_type
#   The destination type for all entries in ``$dest``
#
#   * At this time, if you wish to have different types per destination, you
#     will need to either create a ``rsyslog::rule::remote`` for each destnation
#     or craft your own ruleset and leave ``$dest`` empty.
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
#   * This is only used to set the StreamDriver directive in the forwarding
#     actions for remote servers if TLS is enabled and ``$dest_type`` is
#     not UDP.
#
#   * Overridden by 'DefaultNetstreamDriver' global stream configuration
#     specified by ``rsyslog::config::default_net_stream_driver``.
#
# @param stream_driver_mode
#   * This is only used to set the StreamDriverMode directive in the
#     forwarding actions for remote servers if TLS is enabled and
#     ``$dest_type`` is not UDP.
#
#   * For Rsyslog 7,  the stream driver mode must be **ALSO** be set by
#     the 'ActionSendStreamDriverMode' global stream configuration via
#   ``rsyslog::config::action_send_stream_driver_mode``.
#
# @param stream_driver_auth_mode
#   This is only used to set the StreamDriverAuthMode directive in the
#   forwarding actions for remote servers if TLS is enabled and
#   ``$dest_type`` is not UDP.
#
# @param stream_driver_permitted_peers
#   * This is only used to set the StreamDriverPermittedPeers directive
#     in the forwarding actions for remote servers if TLS is enabled and
#     ``$dest_type`` is not UDP.
#
#   * If this is set, the value will be used for all forwarding actions
#     for the remote servers in ``$dest`` and ``$failover_log_servers``.
#
#   * If this is undefined,
#
#     - If *ALL* of the remote servers in ``$dest`` and
#       ``$failover_log_servers`` are specified as a hostname variants, the
#       StreamDriverPermittedPeers directive for the forwarding action for
#       each server will be set to that server's hostname.
#
#     - If *ANY* and of the remote servers in ``$dest`` and
#       ``$failover_log_servers`` is specified as an IP address variant, the
#       StreamDriverPermittedPeers directive for the forwarding action for
#       each server will be set to the domain of the Puppet client.
#       This behavior provides backward compatibility with earlier
#       versions of this module.
#
#   * rsyslog expects StreamDriverPermittedPeers to be a comma-separated
#     list of fingerprints (SHA1) and/or names of remote peers, which it
#     will use to match against the certificate presented from the remote
#     server.
#
#   * @see https://media.readthedocs.org/pdf/rsyslog/stable/rsyslog.pdf
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
# @param content
#   the **entire* content of the rsyslog::rule
#
#   * If you do not specify this, ``$rule`` is a required variable
#
#   * If you do specify this, ``$rule`` will be ignored
#
# @see https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see http://www.rsyslog.com/doc/expression.html Expressions in Rsyslog
#
# @see http://www.rsyslog.com/doc/rainerscript.html RainerScript Documentation
#
# @see https://simp.readthedocs.io/en/master/user_guide/HOWTO/Central_Log_Collection.html
define rsyslog::rule::remote (
  Optional[String[1]]                              $rule                                 = undef,
  Boolean                                          $stop_processing                      = false,
  Optional[String[1]]                              $template                             = undef,
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
  Optional[String[1]]                              $stream_driver                        = undef,
  Integer[0]                                       $stream_driver_mode                   = 1,
  String                                           $stream_driver_auth_mode              = 'x509/name',
  Optional[String[1]]                              $stream_driver_permitted_peers        = undef,
  Boolean                                          $resend_last_msg_on_reconnect         = true,
  Boolean                                          $udp_send_to_all                      = false,
  Optional[String[1]]                              $queue_filename                       = undef,
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
  String[1]                                        $queue_max_file_size                  = '1m',
  Boolean                                          $queue_save_on_shutdown               = true,
  Integer[0]                                       $queue_dequeue_slowdown               = 0,
  Optional[Integer[0]]                             $queue_dequeue_time_begin             = undef,
  Optional[Integer[0]]                             $queue_dequeue_time_end               = undef,
  Optional[String[1]]                              $content                              = undef
) {
  include '::rsyslog'

  $_notify_msg = 'TLS is being used and stream_driver_permitted_peers is undefined. In this case, rsyslog::remote::rule uses the name supplied in the dest and/or failover_log_server field for the action. If IP Addresses are being used, this will probably not match the CN or fingerprint of the certificate being presented from the log server and the connection will be denied.  The StreamDriverPermittedPeers directive was defaulted to "*.${facts["domain"]}".  The rule being defined should be reviewed to ensure this is valid. It is recommended to use FQDN in the dest and failover_log_server parameters if TLS is being used or specifically set the stream_driver_permitted_peers parameter' # lint:ignore:single_quote_string_with_variables

  $_safe_name = regsubst($name,'/','__')

  unless ($rule or $content) {
    fail('You must specify "$rule" if you are not specifying "$content"')
  }

  if $content {
    $_content = $content
  }
  else {
    if empty($dest) {
      $_dest = $::rsyslog::log_servers
    }
    else {
      $_dest = $dest
    }

    if empty($_dest) { fail('You must pass a destination array for $dest') }

    if $queue_filename {
      $_queue_filename = $queue_filename
    }
    else {
      $_queue_filename = "${_safe_name}_disk_queue"
    }

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

    if $_use_tls {
      if $stream_driver_permitted_peers  {
        $_stream_driver_permitted_peers = $stream_driver_permitted_peers
      } else {
        # If $stream_driver_permitted_peers is not defined, then determine if
        # you should can use the hostname of each server or must fallback
        # to the client's domain.
        $_all_servers = [$_dest, $_failover_servers].flatten
        $_filtered = $_all_servers.filter |$server|  {
          $result = assert_type(Variant[Simplib::IP, Simplib::IP::CIDR, Simplib::IP::V4::DDQ], $server) |$expected, $actual| { }
          $result != undef
        }
        if $_filtered.empty {
          # No IP address variants found, so use remote server hostnames
          $_stream_driver_permitted_peers = undef
        } else {
          # At least 1 IP address variant found, so, for backwards
          # compatibility, use the client's domain as a best-effort guess
          $_stream_driver_permitted_peers = "*.${facts['domain']}"
          notify { "TLS StreamDriverPermittedPeers ${name}":
            message  => ("rsyslog::rule::remote ${_notify_msg}"),
            loglevel => 'warning'
          }
        }
      }
    }

    $_content = template("${module_name}/rule/remote.erb")
  }

  rsyslog::rule { "10_simp_remote/${_safe_name}.conf":
    content => $_content
  }
}
