# == Define: rsyslog::rule::console
#
# Add a console rule to RSyslog.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory. These rules
# are added first of all of the SIMP rules. In general, the order will be:
#  - Console Rules
#  - Drop Rules
#  - Remote Rules
#  - Local Rules
#
# Example:
#   rsyslog::rule::console { 'emergency_rule':
#     rule  => '*.emerg',
#     users => '*'
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
define rsyslog::rule::console (
  $rule,
  $users,
) {
  validate_string($rule)
  validate_string($users)

  file { "/etc/rsyslog.simp.d/06_simp_console/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %>
action(type="omusrmsg" Users="<%= @users %>")'
    ),
    notify  => Service['rsyslog']
  }
}
