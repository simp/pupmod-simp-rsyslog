# @summary The files that exist in `00_simp_pre_logging` on the node
#
# Read from the `rsyslog_simp_config` fact, so it describes the node at the
# start of the run. Empty when the fact is not available.
#
# @return [Array[String]]
#   The file names, e.g. `10_global.conf`
#
# @api private
#
function rsyslog::existing_pre_logging() >> Array[String] {
  $_config = $facts['rsyslog_simp_config']

  if $_config =~ Hash and $_config['rule_dir'] == $rsyslog::rule_dir {
    pick($_config['pre_logging'], [])
  }
  else {
    []
  }
}
