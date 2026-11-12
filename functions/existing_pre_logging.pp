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
  pick(rsyslog::existing_config()['pre_logging'], [])
}
