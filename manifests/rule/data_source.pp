# @summary Add a rule for collecting logs from files on the system
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
# @example Collect Logs From ``/opt/log/my_app``
#   rsyslog::rule::data_source { 'new_input':
#     rule => @(EOM)
#       input(type="imfile"
#         File="/opt/log/my_app"
#         StateFile="my_app"
#         Tag="my_app"
#         Facility="local6"
#         Severity="notice"
#       )
#       |EOM
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
#
define rsyslog::rule::data_source (
  String $rule,
) {
  $_safe_name = regsubst($name, '/', '__')

  rsyslog::rule { "05_simp_data_sources/${_safe_name}.conf":
    content => inline_epp('<%= $rule.split("\n").map |$x| { $x.lstrip() }.join("\n") %>'),
  }
}
