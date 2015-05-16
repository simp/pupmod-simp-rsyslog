# == Class: rsyslog::global
#
# Setup the global section of /etc/rsyslog.conf.
#
# == Parameters
#
# Almost all of the variables come directly from rsyslog. The ones
# that do not, or have unusual behavior, are noted here.
#
# [*mainMsgQueueSize*]
#   Type: Integer
#   Default: The minimum of 1% of physical memory or 1G, based on a 512B message size.
#     The maximum number of messages that may be stored in the memory queue.
#
# [*mainMsgQueueHighWatermark*]
#   Type: Integer
#   Default: 98% of $mainMsgQueueSize
#     The point at which the queue will start writing messages to disk
#     as a number of messages.
#
# [*mainMsgQueueLowWatermark*]
#   Type: Integer
#   Default: 70% of $mainMsgQueueSize
#     The point at which the queue will stop writing messages to disk
#     as a number of messages.
#
#     This must be *lower* than _mainMsgQueueHighWaterMark_
#
# [*mainMsgQueueDiscardmark*]
#   Type: Integer
#   Default: 2X of $mainMsgQueueSize
#   The point at which the queue will discard messages.
#
# [*mainMsgQueueWorkerThreadMinimumMessages*]
#   Type: Integer
#   Default: ''
#     The minimum number of messages in the queue before a new thread
#     can be spawned.
#
#     If left empty (the default), will calculate the value based on
#     the following formula:
#       $mainMsgQueueSize/(($processorcount - 1)*4)
#
# [*mainMsgQueueWorkerThreads*]
#   Type: Integer
#   Default: ''
#     The maximum number of threads to spawn on the system. Defaults
#     to $processorcount - 1.
#
# [*mainMsgQueueMaxDiskSpace*]
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
#     If not specified, will default to ($mainMsgQueueSize * 1024)
#
# [*mainMsgQueueMaxFileSize*]
#   Type: Integer
#   Default: '5'
#     The maximum file size, in Megabytes, that should be created when
#     buffering to disk. It is not recommended to make this
#     excessively large.
#
#
# [*defaultTemplate*]
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
# [*tcpserver*]
#     Set to true if the system is a syslog server.
#
# [*tcpServerRun*]
#     Type: Port
#     Default: '514'
#       The port upon which to listen for unencrypted TCP connections.
#
# [*use_tls*]
#   Type: Boolean
#   Default: true
#     If true, use TLS for TCP connections by default.
#
# [*tls_tcpserver*]
#   Type: Boolean
#   Default: false
#     If true, run an encrypted TCP listener.
#
# [*tls_tcpMaxSessions*]
#     The maximum number of sessions to support. 200 is default.
#
# [*tls_tcpServerRun*]
#   Type: Port
#   Default: '6514'
#     If _$tls_tcpserver_ is true, designates the port upon which to
#     listen for incoming encrypted sessions. The port should not be
#     changed if you are using SELinux.
#
# [*use_simp_pki*]
#   Type: Boolean
#   Default: true
#     If true, use the SIMP 'pki' module to provide system
#     certificates.
#
# [*cert_source*]
#   Type: Absolute Path
#   Default: ''
#     If _$use_simp_pki_ is false, then pull all certificates from
#     this valid Puppet File resource source. They should be in the
#     same format as expected from the SIMP PKI structure.
#     Example Layout:
#       private/<fqdn>.pem
#       public/<fqdn>.pub
#       cacerts/cacerts.pem <- All CA certificates go here!
#
# [*umask*]
#   The umask that should be applied to the running process.
#
# [*ulimit_max_open_files*]
#   The ulimit that should be set for the syslog server.
#   1024 is fine for most purposes, but a collection server should bump this
#   *way* up.
#
# [*compat_mode*]
#   Sysconfig option to note what compatibility mode rsyslog is running in.
#   See the -c option in rsyslogd(8) for more information.
#
# [*hostlist*]
#   Sysconfig Option
#   Array of hosts to be logged with their simple hostname.
#   See the -l option in rsyslogd(8) for more information.
#
# [*domainlist*]
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
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class rsyslog::global (
  $preserveFQDN = 'on',
  $system_log_rate_limit_interval = '0',
  $system_log_rate_limit_burst = '1000',
  $mainMsgQueueType = 'LinkedList',
  $mainMsgQueueFilename = 'main_msg_queue',
  $mainMsgQueueMaxFileSize = '5',
  $mainMsgQueueSize = '',
  $mainMsgQueueHighWatermark = '',
  $mainMsgQueueLowWatermark = '',
  $mainMsgQueueDiscardmark = '',
  $mainMsgQueueWorkerThreadMinimumMessages = '',
  $mainMsgQueueWorkerThreads = '',
  $mainMsgQueueWorkerTimeoutThreadShutdown = '5000',
  $mainMsgQueueTimeoutEnqueue = '100',
  $mainMsgQueueDequeueSlowdown = '0',
  $mainMsgQueueSaveOnShutdown = 'on',
  $mainMsgQueueMaxDiskSpace = '',
  $actionResumeInterval = '30',
  $actionResumeRetryCount = '-1',
  $tcpAllowedSender = [ '127.0.0.1', hiera('client_nets') ],
  $controlCharacterEscapePrefix = '#',
  $defaultTemplate = 'original',
  $dirCreateMode = '0750',
  $dirGroup = 'root',
  $dirOwner = 'root',
  $dropMsgsWithMaliciousDnsPTRRecords = 'off',
  $escapeControlCharactersOnReceive = 'on',
  $fileCreateMode = '0640',
  $fileGroup = 'root',
  $fileOwner = 'root',
  $includeConfig = '/etc/rsyslog.d/*.conf',
  $repeatedMsgReduction = 'on',
  $workDirectory = '/var/spool/rsyslog',
  $interval = '0',
  $tcpserver = false,
  $tcpServerRun = '514',
  $use_tls = true,
  $tls_tcpserver = false,
  $tls_tcpServerRun = '6514',
  $tls_tcpMaxSessions= '200',
  $tls_inputTCPServerStreamDriverPermittedPeers = ["*.${::domain}"],
  $use_simp_pki = true,
  $cert_source = '',
  $defaultNetStreamDriverCAFile = '/etc/rsyslog.d/pki/cacerts/cacerts.pem',
  $defaultNetStreamDriverCertFile = "/etc/rsyslog.d/pki/public/${::fqdn}.pub",
  $defaultNetStreamDriverKeyFile = "/etc/rsyslog.d/pki/private/${::fqdn}.pem",
  $actionSendStreamDriverPermittedPeers = hiera('log_servers',[]),
  $actionSendStreamDriverAuthMode = 'x509/name',
  $udpserver = false,
  $udpServerAddress = '127.0.0.1',
  $udpServerRun = '514',
  $udpAllowedSender = [ '127.0.0.1', hiera('client_nets') ],
  $umask = '0027',
  $ulimit_max_open_files = 'unlimited',
  $compat_mode = '5',
  $hostlist = '',
  $domainlist = '',
  $suppress_noauth_warn = false,
  $disable_remote_dns = false
) {
  include 'rsyslog'
  include 'tcpwrappers'

  concat_fragment { 'rsyslog+global':
    content => template('rsyslog/rsyslog.conf.global.erb'),
    require => File['/var/spool/rsyslog']
  }

  file { '/etc/sysconfig/rsyslog':
    owner    => 'root',
    group    => 'root',
    mode     => '0644',
    content  => template('rsyslog/sysconfig.erb'),
    notify   => Service['rsyslog']
  }

  # Set the maximum number of open files in the init script.
  init_ulimit { 'mod_open_files_rsyslog':
    target      => 'rsyslog',
    item        => 'max_open_files',
    value       => $ulimit_max_open_files,
    notify      => Service['rsyslog']
  }

  # This is blocked two other places, adding this to tcpwrappers is a bit
  # overkill and prone to strange errors.
  if $tcpserver {
    tcpwrappers::allow { 'syslog':
      pattern => 'ALL'
    }
  }
  if $tls_tcpserver {
    tcpwrappers::allow { 'syslog_tls':
      pattern => 'ALL'
    }
  }

  if $use_tls or $tls_tcpserver {
    package { 'rsyslog-gnutls':
      ensure => 'latest',
      notify => Service['rsyslog']
    }

    if $use_simp_pki {
      include 'pki'

      ::pki::copy { '/etc/rsyslog.d':
        notify  => Service['rsyslog']
      }
    }
    else {
      file { '/etc/rsyslog.d/pki':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        source => $cert_source,
        notify => Service['rsyslog']
      }
    }
  }

  validate_array_member($preserveFQDN,['on','off'])
  validate_integer($system_log_rate_limit_interval)
  validate_integer($system_log_rate_limit_burst)
  validate_array_member($mainMsgQueueType,['LinkedList','FixedArray'])
  validate_string($mainMsgQueueFilename)
  if !empty($mainMsgQueueSize) { validate_integer($mainMsgQueueSize) }
  if !empty($mainMsgQueueHighWatermark) { validate_integer($mainMsgQueueHighWatermark) }
  if !empty($mainMsgQueueLowWatermark) { validate_integer($mainMsgQueueLowWatermark) }
  if !empty($mainMsgQueueDiscardmark) { validate_integer($mainMsgQueueDiscardmark) }
  if !empty($mainMsgQueueWorkerThreadMinimumMessages) { validate_integer($mainMsgQueueWorkerThreadMinimumMessages) }
  if !empty($mainMsgQueueWorkerThreads) { validate_integer($mainMsgQueueWorkerThreads) }
  validate_integer($mainMsgQueueWorkerTimeoutThreadShutdown)
  validate_integer($mainMsgQueueTimeoutEnqueue)
  validate_integer($mainMsgQueueDequeueSlowdown)
  validate_array_member($mainMsgQueueSaveOnShutdown,['on','off'])
  if !empty($mainMsgQueueMaxDiskSpace) { validate_re($mainMsgQueueMaxDiskSpace,'^\d+[KMGTP]?$') }
  validate_integer($mainMsgQueueMaxFileSize)
  validate_integer($actionResumeInterval)
  validate_integer($actionResumeRetryCount)
  validate_net_list(flatten($tcpAllowedSender))
  validate_umask($dirCreateMode)
  validate_array_member($dropMsgsWithMaliciousDnsPTRRecords,['on','off'])
  validate_array_member($escapeControlCharactersOnReceive,['on','off'])
  validate_umask($fileCreateMode)
  validate_absolute_path($includeConfig)
  validate_array_member($repeatedMsgReduction,['on','off'])
  validate_absolute_path($workDirectory)
  validate_integer($interval)
  validate_bool($tcpserver)
  validate_port($tcpServerRun)
  validate_bool($use_tls)
  validate_bool($tls_tcpserver)
  validate_port($tls_tcpServerRun)
  validate_integer($tls_tcpMaxSessions)
  validate_array($tls_inputTCPServerStreamDriverPermittedPeers)
  validate_bool($use_simp_pki)
  if !empty($cert_source) { validate_string($cert_source) }
  validate_absolute_path($defaultNetStreamDriverCAFile)
  validate_absolute_path($defaultNetStreamDriverCertFile)
  validate_absolute_path($defaultNetStreamDriverKeyFile)
  validate_array($actionSendStreamDriverPermittedPeers)
  validate_string($actionSendStreamDriverAuthMode)
  validate_bool($udpserver)
  validate_net_list($udpServerAddress)
  validate_port($udpServerRun)
  validate_net_list(flatten($udpAllowedSender))
  validate_umask($umask)
  validate_re($ulimit_max_open_files,'^(unlimited|[0-9]*)$')
  validate_integer($compat_mode)
  validate_bool($suppress_noauth_warn)
  validate_bool($disable_remote_dns)
}
