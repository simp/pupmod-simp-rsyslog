# @summary Adds an arbitrary rule
#
# The main reason to use this is to ensure proper ordering in the stack. If you
# want to insert a rule anywhere, use the ``$rsyslog::rule`` Defined Type
#
# In general, the order will be:
#
#   * Data Source Rules
#   * Console Rules
#   * Drop Rules
#   * Remote Rules
#   * Other/Miscellaneous Rules
#   * Local Rules
#
# @example Send All ``local0`` Messages to ``1.2.3.4`` via TCP
#   rsyslog::rule::other { 'send_local0_away':
#     rule =>  "if prifilt('local0.*') then @@1.2.3.4"
#   }
#
# @param name [String]
#   The filename that you will be dropping into place
#
# @param rule
#   The Rsyslog ``EXPRESSION`` to filter on
#
# @see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-viewing_and_managing_log_files#s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/expressions.html Expressions in Rsyslog
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/index.html RainerScript Documentation
#
#   The filename that you will be dropping into place.
#fine: rsyslog::rule::other
#
define rsyslog::rule::other (
  String $rule
) {
  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "20_simp_other/${_safe_name}.conf":
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") %>')
  }
}
