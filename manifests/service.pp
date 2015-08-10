# == Class: rsyslog::service
#
# Ensure the RSyslog daemon stays running.
#
# == Authors
#
# * Mike Riddle <mriddle@onyxpoint.com>
# * Kendall Moore <kmoore@keywcorp.com>
#
class rsyslog::service {
  service { 'rsyslog':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true
  }
}
