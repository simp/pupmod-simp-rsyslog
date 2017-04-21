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
  Enum['daily','weekly','monthly','yearly'] $rotate_period   = 'daily',
  Integer[0]                                $rotate_preserve = 7,
  Optional[Integer[0]]                      $rotate_size     = undef
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
    size                      => $rotate_size,
    rotate_period             => $rotate_period,
    rotate                    => $rotate_preserve,
    lastaction_restart_logger => true,
    missingok                 => true
  }
}
