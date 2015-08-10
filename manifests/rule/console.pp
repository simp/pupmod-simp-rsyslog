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
  $users
) {
  validate_string($rule)
  validate_array($users)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "06_simp_console/${_safe_name}.conf":
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %> action( type="omusrmsg"
  <%= @users.sort.map{|x| user = %(Users="#{x}")}.join("\n  ") %>
)'
    )
  }
}
