# Add a rule targeting writing local system logs
#
# **NOTE:** Any option that is not explicitly documented here matches the
# ``ruleset`` options in the Rsyslog documentation.
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
# @example Capture OpenLDAP Logs Then Stop Processing
#   rsyslog::rule::local { 'collect_openldap':
#     rule            => "prifilt('local4.*')",
#     target_log_file => '/var/log/slapd.log',
#     stop_processing => true
#   }
#
# @param name [String]
#   The filename that you will be dropping into place
#
# @param rule
#   The Rsyslog ``EXPRESSION`` to filter on
#
#   * **NOTE:** Do **NOT** include the leading ``if/then``
#       * Correct:   ``rule => "prifilt('*.*')"
#       * Incorrect: ``rule => "if prifilt('*.*') then"``
#
#   * This **must** be set if ``$content`` is left empty
#
# @param target_log_file
#   The target log file that omfile will be writing to
#
#   * This **must** be set if ``$dyna_file`` is left empty
#
# @param stop_processing
#   Do not forward logs to any further ``ruleset``s after processing this ``ruleset``
#
# @param dyna_file
#   Set a ``dynamic`` filename using the property replacer rules
#
#   * **NOTE:** If you make this the filename path itself, a template will
#     automatically be created for you. Otherwise, you must make sure to have a
#     rsyslog template in place and pass the **name of the template** to this
#     option
#
#   * Rsyslog templates can be created using the ``rsyslog::template::*``
#     defined types
#
# @param template
# @param dyna_file_cache_size
# @param zip_level
# @param very_robust_zip
# @param flush_interval
# @param async_writing
# @param flush_on_tx_end
# @param io_buffer_size
# @param dir_owner
# @param dir_owner_num
# @param dir_group
# @param dir_group_num
# @param file_owner
# @param file_owner_num
# @param file_group
# @param file_group_num
# @param file_create_mode
# @param dir_create_mode
# @param fail_on_chown_failure
# @param create_dirs
# @param sync
# @param sig_provider
# @param cry_provider
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
define rsyslog::rule::local (
  Optional[String]                                $rule                                 = undef,
  Optional[Stdlib::Absolutepath]                  $target_log_file                      = undef,
  Boolean                                         $stop_processing                      = false,
  Optional[String]                                $dyna_file                            = undef,
  Optional[String]                                $template                             = undef,
  Integer[0]                                      $dyna_file_cache_size                 = 10,
  Integer[0,9]                                    $zip_level                            = 0,
  Boolean                                         $very_robust_zip                      = true,
  Integer[0]                                      $flush_interval                       = 0,
  Boolean                                         $async_writing                        = false,
  Boolean                                         $flush_on_tx_end                      = true,
  Optional[Integer[0]]                            $io_buffer_size                       = undef,
  Optional[String]                                $dir_owner                            = undef,
  Optional[Integer[0]]                            $dir_owner_num                        = undef,
  Optional[String]                                $dir_group                            = undef,
  Optional[Integer[0]]                            $dir_group_num                        = undef,
  Optional[String]                                $file_owner                           = undef,
  Optional[Integer[0]]                            $file_owner_num                       = undef,
  Optional[String]                                $file_group                           = undef,
  Optional[Integer[0]]                            $file_group_num                       = undef,
  String                                          $file_create_mode                     = '0644',
  String                                          $dir_create_mode                      = '0700',
  Boolean                                         $fail_on_chown_failure                = true,
  Boolean                                         $create_dirs                          = true,
  Boolean                                         $sync                                 = false,
  Optional[String]                                $sig_provider                         = undef,
  Optional[String]                                $cry_provider                         = undef,
  Optional[Stdlib::Absolutepath]                  $queue_filename                       = undef,
  Optional[Stdlib::Absolutepath]                  $queue_spool_directory                = undef,
  Optional[Integer[0]]                            $queue_size                           = undef,
  Integer[0]                                      $queue_dequeue_batch_size             = 16,
  Optional[Integer[0]]                            $queue_max_disk_space                 = undef,
  Optional[Integer[0]]                            $queue_high_watermark                 = undef,
  Integer[0]                                      $queue_low_watermark                  = 2000,
  Optional[Integer[0]]                            $queue_full_delay_mark                = undef,
  Optional[Integer[0]]                            $queue_light_delay_mark               = undef,
  Integer[0]                                      $queue_discard_mark                   = 9750,
  Integer[0]                                      $queue_discard_severity               = 8,
  Optional[Integer[0]]                            $queue_checkpoint_interval            = undef,
  Boolean                                         $queue_sync_queue_files               = false,
  Enum['FixedArray','LinkedList','Direct','Disk'] $queue_type                           = 'Direct',
  Integer[0]                                      $queue_worker_threads                 = 1,
  Integer[0]                                      $queue_timeout_shutdown               = 0,
  Integer[0]                                      $queue_timeout_action_completion      = 1000,
  Integer[0]                                      $queue_timeout_enqueue                = 2000,
  Integer[0]                                      $queue_timeout_worker_thread_shutdown = 60000,
  Integer[0]                                      $queue_worker_thread_minimum_messages = 100,
  String                                          $queue_max_file_size                  = '1m',
  Boolean                                         $queue_save_on_shutdown               = false,
  Integer[0]                                      $queue_dequeue_slowdown               = 0,
  Optional[Integer[0]]                            $queue_dequeue_time_begin             = undef,
  Optional[Integer[0]]                            $queue_dequeue_time_end               = undef,
  Optional[String]                                $content                              = undef
) {

  unless ($rule or $content) {
    fail('You must specify "$rule" if you are not specifying "$content"')
  }

  $_safe_name = regsubst($name,'/','__')

  if $content {
    $_content = $content
  }
  else {
    if !($dyna_file or $target_log_file) {
      fail('You must specify one of $dyna_file or $target_log_file')
    }
    $_content = template("${module_name}/rule/local.erb")
  }

  rsyslog::rule { "99_simp_local/${_safe_name}.conf":
    content => $_content
  }
}
