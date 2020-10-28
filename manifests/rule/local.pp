# @summary Add a rule targeting writing local system logs
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
# NOTE: Since many of the parameters here may need to be modified on a
# case-by-base basis, this defined type uses capabilities presented by the
# ``simplib::dlookup`` function to allow for either global overrides or
# instance-specific overrides.
#
# Global overrides work the same way as classes
# (``rsyslog::rule::local::file_create_mode: '0644'``) but will affect **all**
# instances of the defined type that are not specifically overridden as shown
# below.
#
# Instance specific overrides preclude the need for a resource collector in
# that you can place the follwing in Hiera to affect a single instance named
# ``my_rule``: ``Rsyslog::Rule::Local[my_rule]::file_create_mode: '0600'``
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
# @param queue_validation_log_level
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
  Optional[String[1]]            $rule                                 = undef,
  Optional[Stdlib::Absolutepath] $target_log_file                      = undef,
  Boolean                        $stop_processing                      = false,
  Optional[String[1]]            $dyna_file                            = undef,
  Optional[String[1]]            $template                             = undef,
  Integer[0]                     $dyna_file_cache_size                 = 10,
  Integer[0,9]                   $zip_level                            = 0,
  Boolean                        $very_robust_zip                      = true,
  Integer[0]                     $flush_interval                       = 0,
  Boolean                        $async_writing                        = false,
  Boolean                        $flush_on_tx_end                      = true,
  Optional[Integer[0]]           $io_buffer_size                       = undef,
  Optional[String[1]]            $dir_owner                            = undef,
  Optional[Integer[0]]           $dir_owner_num                        = undef,
  Optional[String[1]]            $dir_group                            = undef,
  Optional[Integer[0]]           $dir_group_num                        = undef,
  Optional[String[1]]            $file_owner                           = undef,
  Optional[Integer[0]]           $file_owner_num                       = undef,
  Optional[String[1]]            $file_group                           = undef,
  Optional[Integer[0]]           $file_group_num                       = undef,
  Stdlib::Filemode               $file_create_mode                     = simplib::dlookup('rsyslog::rule::local', 'file_create_mode', $name, { 'default_value' => '0640' }),
  Stdlib::Filemode               $dir_create_mode                      = simplib::dlookup('rsyslog::rule::local', 'dir_create_mode', $name, { 'default_value' => '0750' }),
  Boolean                        $fail_on_chown_failure                = true,
  Boolean                        $create_dirs                          = true,
  Boolean                        $sync                                 = false,
  Optional[String[1]]            $sig_provider                         = undef,
  Optional[String[1]]            $cry_provider                         = undef,
  Simplib::PuppetLogLevel        $queue_validation_log_level           = simplib::dlookup('rsyslog::rule::local', 'queue_validation_log_level', $name, { 'default_value' => 'warning' }),
  Optional[Stdlib::Absolutepath] $queue_filename                       = undef,
  Optional[Stdlib::Absolutepath] $queue_spool_directory                = undef,
  Optional[Integer[0]]           $queue_size                           = undef,
  Optional[Integer[0]]           $queue_dequeue_batch_size             = undef,
  Optional[Integer[0]]           $queue_max_disk_space                 = undef,
  Optional[Integer[0]]           $queue_high_watermark                 = undef,
  Optional[Integer[0]]           $queue_low_watermark                  = undef,
  Optional[Integer[0]]           $queue_full_delay_mark                = undef,
  Optional[Integer[0]]           $queue_light_delay_mark               = undef,
  Optional[Integer[0]]           $queue_discard_mark                   = undef,
  Optional[Integer[0]]           $queue_discard_severity               = undef,
  Optional[Integer[0]]           $queue_checkpoint_interval            = undef,
  Boolean                        $queue_sync_queue_files               = false,
  Rsyslog::QueueType             $queue_type                           = 'Direct',
  Optional[Integer[0]]           $queue_worker_threads                 = undef,
  Optional[Integer[0]]           $queue_timeout_shutdown               = undef,
  Optional[Integer[0]]           $queue_timeout_action_completion      = undef,
  Optional[Integer[0]]           $queue_timeout_enqueue                = undef,
  Optional[Integer[0]]           $queue_timeout_worker_thread_shutdown = undef,
  Optional[Integer[0]]           $queue_worker_thread_minimum_messages = undef,
  Optional[String[1]]            $queue_max_file_size                  = simplib::dlookup('rsyslog::rule::local', 'queue_max_file_size', $name, { 'default_value' => undef }),
  Boolean                        $queue_save_on_shutdown               = false,
  Optional[Integer[0]]           $queue_dequeue_slowdown               = undef,
  Optional[Integer[0]]           $queue_dequeue_time_begin             = undef,
  Optional[Integer[0]]           $queue_dequeue_time_end               = undef,
  Optional[String[1]]            $content                              = undef
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

    # Basic validation for the action queue parameters
    if $queue_size {
      # First check the queue size, which should not be less than 100 per the docs
      if $queue_size < 100 {
        # Warn the user about an errant configuration, but don't fail as RSyslog will still run when setup this way
        notify { "Invalid queue_size specified for ${name}":
          message  => "Action queue size for ${name}: ${queue_size} is less than 100 and can have adverse effects on RSyslog. To disable this message set rsyslog::rule::remote::queue_validation_log_level to 'debug' in Hiera or your ENC",
          loglevel => $queue_validation_log_level,
        }
      }

      # Check to ensure the low watermark is not defined higher than the queue size
      if $queue_low_watermark {
        if ($queue_low_watermark >= $queue_size) {
          # Fail as the low watermark can't be higher than the actual queue size
          fail("Action queue low watermark for ${name}: ${queue_low_watermark} cannot be higher than the queue size: ${queue_size}")
        }
      }

      # Check to ensure the high watermark is not defined higher than the queue size
      if $queue_high_watermark {
        # Fail as the high watermark can't be higher than the actual queue size
        if ($queue_high_watermark >= $queue_size) {
          fail("Action queue high watermark for ${name}: ${queue_high_watermark} cannot be higher than the queue size: ${queue_size}")
        }
      }
    }

    # Make sure that the lower watermark is not defined greater than the high watermark
    if $queue_low_watermark and $queue_high_watermark {
      # Fail as the low watermark can't be higher than the high watermark
      if ($queue_low_watermark >= $queue_high_watermark) {
        fail("Action queue low watermark for ${name} is invalid: ${queue_low_watermark} must be lower than ${queue_high_watermark}")
      }
    }

    $_content = template("${module_name}/rule/local.erb")
  }

  rsyslog::rule { "99_simp_local/${_safe_name}.conf":
    content => $_content
  }
}
