# == Define: rsyslog::rule::local
#
# Add a local rule to RSyslog.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory. These rules
# are added last of all of the SIMP rules. In general, the order will be:
#  - Drop Rules
#  - Remote Rules
#  - Local Rules
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#   Note: Do not include a '/' in the name.
#
# [*rule*]
#   The rule with omfile action that will be placed in the file in the
#   /etc/rsyslog.simp.d directory.
#
# [*target_log_file*]
#  The target log file that omfile will be writing to.
#  Note: This *must* be set if $dyna_file is left empty.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::rule::local (
  $rule,
  $target_log_file                      = '',
  $include_stop                         = false,
  $dyna_file                            = '',
  $template                             = '',
  $dyna_file_cache_size                 = '10',
  $zip_level                            = '0',
  $very_robust_zip                      = true,
  $flush_interval                       =  '0',
  $async_writing                        = false,
  $flush_on_tx_end                      = true,
  $io_buffer_size                       = '',
  $dir_owner                            = '',
  $dir_owner_num                        = '',
  $dir_group                            = '',
  $dir_group_num                        = '',
  $file_owner                           = '',
  $file_owner_num                       = '',
  $file_group                           = '',
  $file_group_num                       = '',
  $file_create_mode                     = '0644',
  $dir_create_mode                      = '0700',
  $fail_on_chown_failure                = true,
  $create_dirs                          = true,
  $sync                                 = false,
  $sig_provider                         = '',
  $cry_provider                         = '',
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
  $queue_type                           = 'Direct',
  $queue_worker_threads                 = '1',
  $queue_timeout_shutdown               = '0',
  $queue_timeout_action_completion      = '1000',
  $queue_timeout_enqueue                = '2000',
  $queue_timeout_worker_thread_shutdown = '60000',
  $queue_worker_thread_minimum_messages = '100',
  $queue_max_file_size                  = '1m',
  $queue_save_on_shutdown               = false,
  $queue_dequeue_slowdown               = '0',
  $queue_dequeue_time_begin             = '',
  $queue_dequeue_time_end               = ''
) {
  validate_string($rule)
  if empty($dyna_file) {
    validate_absolute_path($target_log_file)
  }
  validate_bool($include_stop)
  validate_string($dyna_file)
  validate_string($template)
  validate_integer($dyna_file_cache_size)
  validate_integer($zip_level)
  validate_bool($very_robust_zip)
  validate_integer($flush_interval)
  validate_bool($async_writing)
  validate_bool($flush_on_tx_end)
  validate_string($io_buffer_size)
  validate_string($dir_owner)
  if !empty($dir_owner_num) {
    validate_integer($dir_owner_num)
  }
  validate_string($dir_group)
  if !empty($dir_group_num) {
    validate_integer($dir_group_num)
  }
  validate_string($file_owner)
  if !empty($file_owner_num) {
    validate_integer($file_owner_num)
  }
  validate_string($file_group)
  if !empty($file_group_num) {
    validate_integer($file_group_num)
  }
  validate_umask($file_create_mode)
  validate_umask($dir_create_mode)
  validate_bool($fail_on_chown_failure)
  validate_bool($create_dirs)
  validate_bool($sync)
  validate_string($sig_provider)
  validate_string($cry_provider)
  if !empty($queue_filename) { validate_absolute_path($queue_filename) }
  if !empty($queue_spool_directory) { validate_absolute_path($queue_spool_directory) }
  if !empty($queue_size) { validate_integer($queue_size) }
  validate_integer($queue_dequeue_batch_size)
  if !empty($queue_max_disk_sapce) { validate_integer($queue_max_disk_space) }
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

  file { "/etc/rsyslog.simp.d/99_simp_local/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('rsyslog/local_rule.erb'),
    notify  => Service['rsyslog']
  }
}
