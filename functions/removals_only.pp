# @summary Whether a Hash of parameters only removes parameters
#
# Used for settings whose file must not be created by a removal: removals
# alone apply only to a file that exists.
#
# @param params
#   The parameters, by name. Undef values are ignored.
#
# @return [Boolean]
#   `true` when at least one value is set and every set value is `absent`
#
# @api private
#
function rsyslog::removals_only(
  Optional[Hash] $params,
) >> Boolean {
  $_set = pick($params, {}).filter |$k, $v| { $v =~ NotUndef }

  !empty($_set) and $_set.all |$k, $v| { $v == 'absent' }
}
