# Add a rule to drop content
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
# @see https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see http://www.rsyslog.com/doc/expression.html Expressions in Rsyslog
#
# @see http://www.rsyslog.com/doc/rainerscript.html RainerScript Documentation
#
#   The filename that you will be dropping into place.
#
define rsyslog::rule::drop (
  String $rule
) {
  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "07_simp_drop_rules/${_safe_name}.conf":
    content => inline_template('if (<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") + ") then stop\n" %>')
  }
}
