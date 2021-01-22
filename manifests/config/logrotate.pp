# @summary Default log rotation for RSyslog
#
# The list that is managed here matches the list of default files that are
# managed on the system by this module.
#
# Parameters map to their counterparts in the ``logrotate::rule`` defined type.
# @param rotate_compress
# @param rotate_compresscmd
# @param rotate_uncompresscmd
# @param rotate_compressext
# @param rotate_compressoptions
# @param rotate_copy
# @param rotate_copytruncate
# @param rotate_create
# @param rotate_period
# @param rotate_dateext
# @param rotate_dateformat
# @param rotate_dateyesterday
# @param rotate_delaycompress
# @param rotate_extension
# @param rotate_ifempty
# @param rotate_ext_include
# @param rotate_mail
# @param rotate_maillast
# @param rotate_maxage
# @param rotate_minsize
# @param rotate_missingok
# @param rotate_olddir
# @param rotate_postrotate
# @param rotate_prerotate
# @param rotate_firstaction
# @param rotate_lastaction
# @param rotate_lastaction_restart_logger
# @param rotate_logger_service
# @param rotate_preserve
# @param rotate_size
# @param rotate_sharedscripts
# @param rotate_shred
# @param rotate_shredcycles
# @param rotate_su
# @param rotate_su_user
# @param rotate_su_group
# @param rotate_start
# @param rotate_tabooext
#
# @api private
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

  simplib::assert_optional_dependency($module_name, 'simp/logrotate')

  include 'logrotate'

  logrotate::rule { 'syslog':
    log_files                 => [
      '/var/log/boot.log',
      '/var/log/cron',
      '/var/log/iptables.log',
      '/var/log/firewall.log',
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
