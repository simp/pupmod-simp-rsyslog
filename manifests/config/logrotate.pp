# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Default log rotation for RSyslog
#
# The list that is managed here matches the list of default files that are
# managed on the system by this module.
#
# @param rotate_period
#   How often to rotate the logs
#
# @param rotate_preserve
#   How many rotated logs to keep
#
# @param rotate_size
#   The maximum size of a log file
#
#   * ``$rotate_period`` will be ignored if this is specified
#
class rsyslog::config::logrotate (
  Optional[Boolean]                         $rotate_compress                  = undef,
  Optional[String[1]]                       $rotate_compresscmd               = undef,
  Optional[String[1]]                       $rotate_uncompresscmd             = undef,
  Optional[String[1]]                       $rotate_compressext               = undef,
  Optional[String[1]]                       $rotate_compressoptions           = undef,
  Boolean                                   $rotate_copy                      = false,
  Boolean                                   $rotate_copytruncate              = false,
  Pattern['\d{4} .+ .+']                    $rotate_create                    = '0640 root root',
  Enum['daily','weekly','monthly','yearly'] $rotate_period                    = 'daily',
  Optional[Boolean]                         $rotate_dateext                   = undef,
  String[1]                                 $rotate_dateformat                = '-%Y%m%d.%s',
  Optional[Boolean]                         $rotate_dateyesterday             = undef,
  Optional[Boolean]                         $rotate_delaycompress             = undef,
  Optional[String[1]]                       $rotate_extension                 = undef,
  Boolean                                   $rotate_ifempty                   = false,
  Optional[Array[String[1]]]                $rotate_ext_include               = undef,
  Optional[Simplib::EmailAddress]           $rotate_mail                      = undef,
  Boolean                                   $rotate_maillast                  = true,
  Optional[Integer[0]]                      $rotate_maxage                    = undef,
  Optional[Integer[0]]                      $rotate_minsize                   = undef,
  Boolean                                   $rotate_missingok                 = true,
  Optional[Stdlib::Absolutepath]            $rotate_olddir                    = undef,
  Optional[String[1]]                       $rotate_postrotate                = undef,
  Optional[String[1]]                       $rotate_prerotate                 = undef,
  Optional[String[1]]                       $rotate_firstaction               = undef,
  Optional[String[1]]                       $rotate_lastaction                = undef,
  Boolean                                   $rotate_lastaction_restart_logger = true,
  Optional[String[1]]                       $rotate_logger_service            = simplib::lookup('logrotate::logger_service', {'default_value' => 'rsyslog'}),
  Integer[0]                                $rotate_preserve                  = 7,
  Optional[Integer[0]]                      $rotate_size                      = undef,
  Boolean                                   $rotate_sharedscripts             = true,
  Optional[Boolean]                         $rotate_shred                     = undef,
  Optional[Integer[0]]                      $rotate_shredcycles               = undef,
  Boolean                                   $rotate_su                        = false,
  Optional[String[1]]                       $rotate_su_user                   = undef,
  Optional[String[1]]                       $rotate_su_group                  = undef,
  Integer[0]                                $rotate_start                     = 1,
  Optional[Array[String[1]]]                $rotate_tabooext                  = undef,
){
  assert_private()

  include '::logrotate'

  logrotate::rule { 'syslog':
    log_files                 => [
      '/var/log/boot.log',
      '/var/log/cron',
      '/var/log/iptables.log',
      '/var/log/maillog',
      '/var/log/messages',
      '/var/log/puppet*.log',
      '/var/log/secure',
      '/var/log/slapd*.log',
      '/var/log/spooler'
    ],
    compress                  => $rotate_compress,
    compresscmd               => $rotate_compresscmd,
    uncompresscmd             => $rotate_uncompresscmd,
    compressext               => $rotate_compressext,
    compressoptions           => $rotate_compressoptions,
    copy                      => $rotate_copy,
    copytruncate              => $rotate_copytruncate,
    create                    => $rotate_create,
    rotate_period             => $rotate_period,
    dateext                   => $rotate_dateext,
    dateformat                => $rotate_dateformat,
    dateyesterday             => $rotate_dateyesterday,
    delaycompress             => $rotate_delaycompress,
    extension                 => $rotate_extension,
    ifempty                   => $rotate_ifempty,
    ext_include               => $rotate_ext_include,
    mail                      => $rotate_mail,
    maillast                  => $rotate_maillast,
    maxage                    => $rotate_maxage,
    minsize                   => $rotate_minsize,
    missingok                 => $rotate_missingok,
    olddir                    => $rotate_olddir,
    postrotate                => $rotate_postrotate,
    prerotate                 => $rotate_prerotate,
    firstaction               => $rotate_firstaction,
    lastaction                => $rotate_lastaction,
    lastaction_restart_logger => $rotate_lastaction_restart_logger,
    logger_service            => $rotate_logger_service,
    rotate                    => $rotate_preserve,
    size                      => $rotate_size,
    sharedscripts             => $rotate_sharedscripts,
    shred                     => $rotate_shred,
    shredcycles               => $rotate_shredcycles,
    su                        => $rotate_su,
    su_user                   => $rotate_su_user,
    su_group                  => $rotate_su_group,
    start                     => $rotate_start,
    tabooext                  => $rotate_tabooext,
  }
}
