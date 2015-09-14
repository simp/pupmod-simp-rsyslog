# == Class: rsyslog::logrotate
#
# Sets up log rotation for RSyslog.
#
class rsyslog::config::logrotate {
  include '::logrotate'
  assert_private()

  # Set up the initial logrotate rule
  ::logrotate::add { 'syslog':
    log_files  => [
      '/var/log/messages',
      '/var/log/secure',
      '/var/log/maillog',
      '/var/log/spooler',
      '/var/log/boot.log',
      '/var/log/cron',
      '/var/log/iptables.log',
      '/var/log/puppet*.log'
    ],
    lastaction => '/sbin/service rsyslog restart > /dev/null 2>&1 || true',
    missingok  => true
  }
}
