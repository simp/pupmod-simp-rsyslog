# == Define: rsyslog::rule::drop
#
# Add a drop rule to RSyslog.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory. These rules will
# come before all other SIMP rules in the /etc/rsyslog.simp.d space. In general, the order
# of rules will be:
#  - Drop Rules
#  - Remote Rules
#  - Local Rules
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#   Note: Do not include a '/' in the name.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::rule::drop (
  $rule,
) {
  validate_string($rule)

  file { "/etc/rsyslog.simp.d/07_simp_drop_rules/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") + " then stop" %>'),
    notify  => Service['rsyslog']
  }
}
