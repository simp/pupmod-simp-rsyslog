# @summary The `rsyslog_simp_config` fact, when it describes `rsyslog::rule_dir`
#
# The fact describes the node at the start of the run. When it reports a
# different rule directory (for example after `rsyslog::rule_dir` changed),
# its files and listeners are not the ones this run manages, so it is
# ignored.
#
# @return [Hash]
#   The fact, or an empty Hash when it is not available or describes another
#   rule directory
#
# @api private
#
function rsyslog::existing_config() >> Hash {
  $_config = $facts['rsyslog_simp_config']

  if $_config =~ Hash and $_config['rule_dir'] == $rsyslog::rule_dir {
    $_config
  }
  else {
    {}
  }
}
