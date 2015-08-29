# == Class: rsyslog::config
#
# Setup RSyslog configuration. Creates /etc/rsyslog.conf and includes
# all SIMP config subdirectories in /etc/rsyslog.simp.d.
#
# == Parameters
#
# Almost all of the variables come directly from rsyslog. The ones
# that do not, or have unusual behavior, are noted here.
#
# [*umask*]
#   The umask that should be applied to the running process.
#
# [*main_msg_queue_size*]
#   Type: Integer
#   Default: The minimum of 1% of physical memory or 1G, based on a 512B message size.
#     The maximum number of messages that may be stored in the memory queue.
#
# [*main_msg_queue_high_watermark*]
#   Type: Integer
#   Default: 90% of $main_msg_queue_size
#     The point at which the queue will start writing messages to disk
#     as a number of messages.
#
# [*main_msg_queue_low_watermark*]
#   Type: Integer
#   Default: 70% of $main_msg_queue_size
#     The point at which the queue will stop writing messages to disk
#     as a number of messages.
#
#     This must be *lower* than _main_msg_queue_high_watermark_
#
# [*main_msg_queue_discardmark*]
#   Type: Integer
#   Default: 98% of $main_msg_queue_size
#   The point at which the queue will discard messages.
#
# [*main_msg_queue_worker_thread_minimum_messages*]
#   Type: Integer
#   Default: ''
#     The minimum number of messages in the queue before a new thread
#     can be spawned.
#
#     If left empty (the default), will calculate the value based on
#     the following formula:
#       $main_msg_queue_size/(($processorcount - 1)*4)
#
# [*main_msg_queue_worker_threads*]
#   Type: Integer
#   Default: ''
#     The maximum number of threads to spawn on the system. Defaults
#     to $processorcount - 1.
#
# [*main_msg_queue_max_disk_space*]
#   Type: Integer
#   Default: ''
#     The maximum amount of disk space to use for the disk queue.
#     Specified as a digit followed by a unit specifier. For example:
#       100   -> 100 Bytes
#       100K  -> 100 Kilobytes
#       100M  -> 100 Megabytes
#       100G  -> 100 Gigabytes
#       100T  -> 100 Terabytes
#       100P  -> 100 Petabytes
#     If not specified, will default to ($main_msg_queue_size * 1024)
#
# [*main_msg_queue_max_file_size*]
#   Type: Integer
#   Default: '5'
#     The maximum file size, in Megabytes, that should be created when
#     buffering to disk. It is not recommended to make this
#     excessively large.
#
#
# [*default_template*]
#   The default template to use to output to various services. This one has
#   been designed to work with external parsing tools that require the
#   priority text.
#
#   You can also choose from the following values in order to select from one
#   of the built-in rsyslogd formats.
#     * forward     -> RSYSLOG_Forward
#     * original    -> RSYSLOG_FileFormat
#     * traditional -> RSYSLOG_TraditionalFileFormat
#
# [*interval*]
#     The mark interval.
#
# [*tls_tcp_max_sessions*]
#     The maximum number of sessions to support. 200 is default.
#
# [*cert_source*]
#   Type: Absolute Path
#   Default: ''
#     The directory where PKI (TLS) certificates and keys are stored.
#
#     The directory should be in the following structure:
#       private/<fqdn>.pem
#       public/<fqdn>.pub
#       cacerts/cacerts.pem <- All CA certificates go here!
#
# [*ulimit_max_open_files*]
#   The ulimit that should be set for the syslog server.
#   1024 is fine for most purposes, but a collection server should bump this
#   *way* up.
#
# [*host_list*]
#   Sysconfig Option
#   Array of hosts to be logged with their simple hostname.
#   See the -l option in rsyslogd(8) for more information.
#
# [*domain_list*]
#     Sysconfig Option
#     Array of domains that should be stripped off before logging.
#     See the -s option in rsyslogd(8) for more information.
#
# [*suppress_noauth_warn*]
#   Sysconfig Option
#   Set to someting other than false to suppress warnings due to hosts not in
#   the ACL.
#   See the -w option in rsyslogd(8) for more information.
#
# [*disable_remote_dns*]
#   Sysconfig Option
#   Disable DNS for remote messages.
#   See the -x option in rsyslogd(8) for more information.
#
class rsyslog::config (
  $umask                                              = '0027',
  $preserve_fqdn                                      = true,
  $control_character_escape_prefix                    = '#',
  $drop_msgs_with_malicious_dns_ptr_records           = 'off',
  $escape_control_characters_on_receive               = 'on',
  $default_template                                   = 'original',

  # Parameters for imuxsock with sensible defaults.
  $syssock_ignore_timestamp                           = true,
  $syssock_ignore_own_messages                        = true,
  $syssock_use                                        = true,
  $syssock_name                                       = '',
  $syssock_flow_control                               = false,
  $syssock_use_pid_from_system                        = false,
  $syssock_rate_limit_interval                        = '0',
  $syssock_rate_limit_burst                           = '1000',
  $syssock_rate_limit_severity                        = '5',
  $syssock_use_sys_timestamp                          = true,
  $syssock_annotate                                   = false,
  $syssock_parse_trusted                              = false,
  $syssock_unlink                                     = true,

  # Main message queue global defaults.
  $main_msg_queue_type                                = 'LinkedList',
  $main_msg_queue_filename                            = 'main_msg_queue',
  $main_msg_queue_max_file_size                       = '5',
  $main_msg_queue_size                                = '10000',
  $main_msg_queue_high_watermark                      = '',
  $main_msg_queue_low_watermark                       = '',
  $main_msg_queue_discardmark                         = '',
  $main_msg_queue_worker_thread_minimum_messages      = '',
  $main_msg_queue_worker_threads                      = '',
  $main_msg_queue_worker_timeout_thread_shutdown      = '5000',
  $main_msg_queue_timeout_enqueue                     = '100',
  $main_msg_queue_dequeue_slowdown                    = '0',
  $main_msg_queue_save_on_shutdown                    = 'on',
  $main_msg_queue_max_disk_space                      = '',

  $repeated_msg_reduction                             = 'on',
  $work_directory                                     = '/var/spool/rsyslog',
  $interval                                           = '0',
  $tls_tcp_max_sessions                               = '200',
  # FIXME: handle this as an Array in the template, templates/pre_logging.conf.erb
  $tls_input_tcp_server_stream_driver_permitted_peers = ["*.${::domain}"],

  $default_net_stream_driver_ca_file                  = "${::rsyslog::cert_source}/cacerts/cacerts.pem",
  $default_net_stream_driver_cert_file                = "${::rsyslog::cert_source}/public/${::fqdn}.pub",
  $default_net_stream_driver_key_file                 = "${::rsyslog::cert_source}/private/${::fqdn}.pem",

  ## TODO: Remove these once we upgrade to v7-stable or later.
  $action_send_stream_driver_mode                     = $::rsyslog::enable_pki ? { true => '1', default => '0' },
  $action_send_stream_driver_auth_mode                = '',
  $action_send_stream_driver_permitted_peers          = $::rsyslog::log_server_list,

  $ulimit_max_open_files                              = 'unlimited',
  $host_list                                          = '',
  $domain_list                                        = '',
  $suppress_noauth_warn                               = false,
  $disable_remote_dns                                 = false,
  $enable_default_rules                               = true,
  $include_rsyslog_d                                  = false,
) {

  validate_bool($preserve_fqdn)
  validate_array_member($main_msg_queue_type,['LinkedList','FixedArray'])
  validate_string($main_msg_queue_filename)
  if !empty($main_msg_queue_size) { validate_integer($main_msg_queue_size) }
  if !empty($main_msg_queue_high_watermark) { validate_integer($main_msg_queue_high_watermark) }
  if !empty($main_msg_queue_low_watermark) { validate_integer($main_msg_queue_low_watermark) }
  if !empty($main_msg_queue_discardmark) { validate_integer($main_msg_queue_discardmark) }
  if !empty($main_msg_queue_worker_thread_minimum_messages) { validate_integer($main_msg_queue_worker_thread_minimum_messages) }
  if !empty($main_msg_queue_worker_threads) { validate_integer($main_msg_queue_worker_threads) }
  validate_integer($main_msg_queue_worker_timeout_thread_shutdown)
  validate_integer($main_msg_queue_timeout_enqueue)
  validate_integer($main_msg_queue_dequeue_slowdown)
  validate_array_member($main_msg_queue_save_on_shutdown,['on','off'])
  if !empty($main_msg_queue_max_disk_space) { validate_re($main_msg_queue_max_disk_space,'^\d+[KMGTP]?$') }
  validate_integer($main_msg_queue_max_file_size)
  validate_array_member($drop_msgs_with_malicious_dns_ptr_records,['on','off'])
  validate_array_member($escape_control_characters_on_receive,['on','off'])
  validate_string($default_template)
  validate_array_member($repeated_msg_reduction,['on','off'])
  validate_absolute_path($work_directory)
  validate_integer($interval)
  validate_integer($tls_tcp_max_sessions)
  validate_array($tls_input_tcp_server_stream_driver_permitted_peers)
  validate_absolute_path($default_net_stream_driver_ca_file)
  validate_absolute_path($default_net_stream_driver_cert_file)
  validate_absolute_path($default_net_stream_driver_key_file)
  validate_array($action_send_stream_driver_permitted_peers)
  validate_string($action_send_stream_driver_auth_mode)
  validate_umask($umask)
  validate_re($ulimit_max_open_files,'^(unlimited|[0-9]*)$')
  validate_bool($suppress_noauth_warn)
  validate_bool($disable_remote_dns)
  validate_bool($include_rsyslog_d)
  validate_bool($enable_default_rules)

  include '::rsyslog'

  # set the driver auth_mode based on the mode
  if empty( $action_send_stream_driver_auth_mode ) {
    $l_action_send_stream_driver_auth_mode = $action_send_stream_driver_mode ? {
       '0'     => 'anon',
       '1'     => 'x509/name',
       default => 'x509/name',
    }
  } else {
    $l_action_send_stream_driver_auth_mode = $action_send_stream_driver_auth_mode
  }

  $_default_template = $default_template ? {
    'traditional' => 'RSYSLOG_TraditionalFormat',
    'original'    => 'RSYSLOG_FileFormat',
    'forward'     => 'RSYSLOG_ForwardFormat',
    default       => $default_template
  }

  # This is where the custom rules will go. They will be purged if not
  # managed!
  file { $::rsyslog::rule_dir:
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

  file { '/etc/rsyslog.d/README_SIMP.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => '# Place .conf files that rsyslog should process independently of SIMP into this directory.\n'
  }

  file { '/var/spool/rsyslog':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  if $enable_default_rules {
    rsyslog::rule { '99_simp_local/ZZ_default.conf':
      content => template('rsyslog/rsyslog.default.erb')
    }
  }

  file { '/etc/rsyslog.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('rsyslog/rsyslog.conf.global.erb')
  }

  file { '/etc/sysconfig/rsyslog':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('rsyslog/sysconfig.erb')
  }

  rsyslog::rule { '00_simp_pre_logging/global.conf':
    content => template('rsyslog/pre_logging.conf.erb')
  }

  rsyslog::rule { '09_failover_hack/failover_hack.conf':
    content => '
# For failover to be defined and parse properly, we must place it somewhere
# after the first rule is defined. Therefore, we are creating this noop rule.

if $syslogfacility == \'local0\' and $msg startswith \'placeholder_rule\' then continue'
  }

  if $include_rsyslog_d {
    rsyslog::rule { '15_include_default_rsyslog/include_default_rsyslog.conf':
      content => '$IncludeConfig /etc/rsyslog.d/'
    }
  }

  rsyslog::template::string { 'defaultTemplate':
    string => $_default_template
  }

  # Set the maximum number of open files in the init script.
  init_ulimit { 'mod_open_files_rsyslog':
    target => 'rsyslog',
    item   => 'max_open_files',
    value  => $ulimit_max_open_files
  }
}
