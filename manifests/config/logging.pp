# == Class: rsyslog::logging
#
# Sets up log rotation for RSyslog.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class rsyslog::config::logging {
  include 'logrotate'

  # Set up the initial logrotate rule
  logrotate::add { 'syslog':
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
