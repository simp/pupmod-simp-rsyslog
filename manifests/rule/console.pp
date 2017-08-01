# Add a rule for writing logs to the console
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
# @see https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see http://www.rsyslog.com/doc/expression.html Expressions in Rsyslog
#
# @see http://www.rsyslog.com/doc/rainerscript.html RainerScript Documentation
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
