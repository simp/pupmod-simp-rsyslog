# == Define: rsyslog::config::other
#
# This adds a configuration file to the /etc/rsyslog.d directory.  Take care,
# as these are processed prior to any other rules running.
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#   Note: Do not include a '/' in the name.
#
# [*content*]
#   The literal content of the file that you are placing in the
#   /etc/rsyslog.simp.d directory.
#
# == Authors
#
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
define rsyslog::config::other (
  $content
) {

  file { "/etc/rsyslog.simp.d/06_simp_other/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $content,
    notify => Service['rsyslog']
  }
}
