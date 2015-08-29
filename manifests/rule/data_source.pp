# == Define: rsyslog::rule::data_source
#
# This is meant to be used for collecting information from various data sources
# across your system (or other external systems). These rules are, by default,
# processed before all other rules so that the data stream has all of the
# necessary information.
#
# Example:
#   rsyslog::rule::data_source { 'new_input':
#     rule =>  'input(type="imfile"
#       File="/opt/log/my_app"
#       StateFile="my_app"
#       Tag="my_app"
#       Facility="local6"
#       Severity="notice"
#     )
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
define rsyslog::rule::data_source(
  $rule
) {
  validate_string($rule)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "05_simp_data_sources/${_safe_name}.conf":
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %>')
  }
}
