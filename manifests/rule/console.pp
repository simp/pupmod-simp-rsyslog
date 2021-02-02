# @summary Add a rule for writing logs to the console
#
# These rules first in priority. In general, the order will be:
#
#   * Data Source Rules
#   * Console Rules
#   * Drop Rules
#   * Remote Rules
#   * Other/Miscellaneous Rules
#   * Local Rules
#
# @example Log Emergency Messages to the Console
#   rsyslog::rule::console { 'emergency_rule':
#     rule  => 'prifilt(\'*.emerg\'),
#     users => ['*']
#   }
#
# @param name [String]
#   The filename that you will be dropping into place
#
# @param rule
#   The Rsyslog ``EXPRESSION`` to filter on
#
# @param users
#    Users to which to send the console messages
#
# @see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-viewing_and_managing_log_files#s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/expressions.html Expressions in Rsyslog
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/index.html RainerScript Documentation
#
define rsyslog::rule::console (
  String        $rule,
  Array[String] $users
) {
  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "06_simp_console/${_safe_name}.conf":
    content => inline_template('if (<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %>) then action( type="omusrmsg"
  <%= @users.sort.map{|x| user = %(Users="#{x}")}.join("\n  ") %>
)'
    )
  }
}
