# @summary Add a rule to drop content
#
# In general, the order will be:
#
#   * Data Source Rules
#   * Console Rules
#   * Drop Rules
#   * Remote Rules
#   * Other/Miscellanious Rules
#   * Local Rules
#
# @example Drop Logs Matching ``^.*bad_stuff.*$``
#   rsyslog::rule::drop { 'drop_bad_stuff':
#     rule => 're_match($msg, '^.*bad_stuff.*$')'
#   }
#
# @param name [String]
#   The filename that you will be dropping into place
#
# @param rule
#   The Rsyslog ``EXPRESSION`` to filter on
#
#   * Required unless `$ensure` is `absent`.
#
# @see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-viewing_and_managing_log_files#s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/expressions.html Expressions in Rsyslog
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/index.html RainerScript Documentation
#
#   The filename that you will be dropping into place.
#
# @param ensure
#   `absent` removes the rule file
#
define rsyslog::rule::drop (
  Optional[String]          $rule   = undef,
  Enum['present', 'absent'] $ensure = 'present',
) {
  $_safe_name = regsubst($name,'/','__')

  if $ensure == 'absent' {
    rsyslog::rule { "07_simp_drop_rules/${_safe_name}.conf":
      ensure => 'absent',
    }
  }
  else {
    if $rule =~ Undef {
      fail('$rule is required unless $ensure is absent')
    }

    $_rule = $rule.split("\n").map |$x| { $x.lstrip() }.join("\n")

    rsyslog::rule { "07_simp_drop_rules/${_safe_name}.conf":
      content => "if (${_rule}) then stop\n",
    }
  }
}
