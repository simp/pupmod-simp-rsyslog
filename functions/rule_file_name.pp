# @summary The path, relative to `rsyslog::rule_dir`, that a rule is written to
#
# `hostname` is written as `host_name`: the SELinux policy labels
# `/etc/.*hostname.*` as `hostname_etc_t`, which rsyslog cannot read on EL10.
#
# @param name
#   The rule's name, e.g. `10_simp_remote/forward_hostname.conf`
#
# @return [String]
#   The path the rule is written to, e.g. `10_simp_remote/forward_host_name.conf`
#
# @api private
#
function rsyslog::rule_file_name(
  String[1] $name,
) >> String {
  regsubst($name, 'hostname', 'host_name', 'G')
}
