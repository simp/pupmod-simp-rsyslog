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
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::rule::drop (
  $rule
) {
  validate_string($rule)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "07_simp_drop_rules/${_safe_name}.conf":
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") + " then stop" %>')
  }
}
