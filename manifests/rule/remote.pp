# == Define: rsyslog::rule::remote
#
# Add a remote rule to RSyslog.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory. Take care,
# as these are processed prior to any local rules. In general, the order of rules
# loaded in the /etc/rsyslog.simp.d space will be:
#  - Drop Rules
#  - Remote Rules
#  - Local Rules
#
# This will *not* add a target that is the system that it is being evaluated
# on. This is to prevent syslog loops that will quickly destroy your systems.
#
# Unfortunately, this is not perfect.  We cannot detect if you use a DNS
# alias to the host instead of the true hostname.
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#
# [*content*]
#   The literal content of the file that you are placing in the
#   /etc/rsyslog.d directory.
#
# [*dest*]
#   Type: Array of destination targets
#   Default []
#     If filled, the _$content_ above will be sent to all entries in this
#     array.
#
#     If using this, do NOT add a destination to your content above!
#
#   Example:
#     ['syslog1.my.network','syslog2.my.network']
#
# [*dest_type*]
#   Type: 'tcp','udp', or 'relp'
#   Default: 'tcp'
#     The destination type for all entries in _$dest_ above. At this
#     time, if you wish to have different types per destination, you
#     will need to craft your own full rule set and leave _$dest_
#     empty.
#
# [*omfwd_options*]
#  Type: hash
#  Default:
#
#    The options that can go into the action object for the specific rule.
#    This is currently implemented for RSyslog v7 and later, and thus does
#    not use legacy syslog syntax. For complete documentation on RSyslog
#    omfwd options, visit http://www.rsyslog.com/doc/v7-stable/configuration/modules/omfwd.html
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::rule::remote (
  $rule,
  $dest                                 = hiera('log_servers',[]),
  $dest_type                            = 'tcp',
  $tcp_framing                          = 'traditional',
  $zip_level                            = '0',
  $max_error_messages                   = '5',
  $compression_mode                     = 'none',
  $compression_stream_flush_on_tx_end   = true,
  $rebind_interval                      = '',
  $action_resume_interval               = '30',
  $action_resume_retry_count            = '-1',
  $stream_driver                        = '',
  $stream_driver_mode                   = '1',
  $stream_driver_auth_mode              = 'x509/name',
  $stream_driver_permitted_peers        = "*.${::domain}",
  $resend_last_msg_on_reconnect         = true,
  $udp_send_to_all                      = false,
  $queue_filename                       = '',
  $queue_spool_directory                = '',
  $queue_size                           = '',
  $queue_dequeue_batch_size             = '16',
  $queue_max_disk_space                 = '',
  $queue_high_watermark                 = '',
  $queue_low_watermark                  = '2000',
  $queue_full_delay_mark                = '',
  $queue_light_delay_mark               = '',
  $queue_discard_mark                   = '9750',
  $queue_discard_severity               = '8',
  $queue_checkpoint_interval            = '',
  $queue_sync_queue_files               = false,
  # TODO: TLS failover does *not* work using a disk-assisted (LinkedList) queue here.
  # Use a direct queue if you need failover to function.
  $queue_type                           = 'LinkedList',
  $queue_worker_threads                 = '1',
  $queue_timeout_shutdown               = '0',
  $queue_timeout_action_completion      = '1000',
  $queue_timeout_enqueue                = '2000',
  $queue_timeout_worker_thread_shutdown = '60000',
  $queue_worker_thread_minimum_messages = '100',
  $queue_max_file_size                  = '1m',
  $queue_save_on_shutdown               = true,
  $queue_dequeue_slowdown               = '0',
  $queue_dequeue_time_begin             = '',
  $queue_dequeue_time_end               = ''
) {
  validate_array($dest)
  if empty($dest) { fail('Error: you must pass a destination array for $dest') }
  validate_net_list($dest)
  validate_array_member($dest_type,['tcp','udp','relp'])
  validate_array_member($tcp_framing, ['traditional', 'octet-counted'])
  validate_array_member($zip_level, ['0','1','2','3','4','5','6','7','8','9'])
  validate_integer($max_error_messages)
  validate_array_member($compression_mode, ['none', 'single', 'stream:always'])
  validate_bool($compression_stream_flush_on_tx_end)
  if !empty($rebind_interval) { validate_integer($rebind_interval) }
  validate_string($stream_driver)
  validate_integer($stream_driver_mode)
  validate_string($stream_driver_mode)
  validate_string($stream_driver_auth_mode)
  validate_string($stream_driver_permitted_peers)
  validate_bool($resend_last_msg_on_reconnect)
  validate_bool($udp_send_to_all)
  if !empty($queue_filename) { validate_absolute_path($queue_filename) }
  if !empty($queue_spool_directory) { validate_absolute_path($queue_spool_directory) }
  if !empty($queue_size) { validate_integer($queue_size) }
  validate_integer($queue_dequeue_batch_size)
  if !empty($queue_max_disk_space) { validate_integer($queue_max_disk_space) }
  if !empty($queue_high_watermark) { validate_integer($queue_high_watermark) }
  validate_integer($queue_low_watermark)
  if !empty($queue_full_delay_mark) { validate_integer($queue_full_delay_mark) }
  if !empty($queue_light_delay_mark) { validate_integer($queue_light_delay_mark) }
  validate_integer($queue_discard_mark)
  validate_integer($queue_discard_severity)
  if !empty($queue_checkpoint_interval) { validate_integer($queue_checkpoint_interval) }
  validate_bool($queue_sync_queue_files)
  validate_array_member($queue_type, ['FixedArray','LinkedList','Direct','Disk'])
  validate_integer($queue_worker_threads)
  validate_integer($queue_timeout_shutdown)
  validate_integer($queue_timeout_action_completion)
  validate_integer($queue_timeout_enqueue)
  validate_integer($queue_timeout_worker_thread_shutdown)
  validate_integer($queue_worker_thread_minimum_messages)
  validate_string($queue_max_file_size)
  validate_bool($queue_save_on_shutdown)
  validate_integer($queue_dequeue_slowdown)
  if !empty($queue_dequeue_time_begin) { validate_integer($queue_dequeue_time_begin) }
  if !empty($queue_dequeue_time_end) { validate_integer($queue_dequeue_time_end) }

  include '::rsyslog'

  $_queue_filename = empty($queue_filename) ? {
    true    => "${name}_disk_queue",
    default => $queue_filename
  }
  $_queue_spool_directory = empty($queue_spool_directory) ? {
    true    => $::rsyslog::queue_spool_directory,
    default => $queue_spool_directory
  }
  $_use_tls = $::rsyslog::enable_tls_logging
  $_allow_failover = $::rsyslog::allow_failover
  $_failover_servers = $::rsyslog::failover_log_servers

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "10_simp_remote/${_safe_name}.conf":
    content => template('rsyslog/remote_rule.erb')
  }
}
