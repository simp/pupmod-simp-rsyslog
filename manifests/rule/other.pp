# == Define: rsyslog::rule::other
#
# Add a miscellanious other rule to RSyslog.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory. These rules
# are added first of all of the SIMP rules. In general, the order will be:
#  - Console Rules
#  - Drop Rules
#  - Remote Rules
#  - Other Miscellanious Rules *This define*
#  - Local Rules
#
# Example:
#   rsyslog::rule::other { 'emergency_rule':
#     rule  => '*.emerg'
#   }
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#   Note: Do not include a '/' in the name.
#
# [*rule*]
#   The rule with omfile action that will be placed in the file in the
#   /etc/rsyslog.simp.d directory.
#
# [*users*]
#    An array of users to send the console message to.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::rule::other (
  $rule,
) {
  validate_string($rule)

  file { "/etc/rsyslog.simp.d/20_simp_other/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %>'),
    notify  => Service['rsyslog']
  }
}
