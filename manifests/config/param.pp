# @summary Manage one `key="value"` parameter inside a `rsyslog::config::block`
#
# Declare this only for parameters that are set: an undef parameter means
# "leave the line alone". A value of `absent` removes the line.
#
# @param block
#   The title of the `rsyslog::config::block` holding the parameter
#
# @param header
#   The first line of the block, after which new parameters are inserted
#
# @param key
#   The rsyslog parameter name
#
# @param value
#   The value to write, or `absent` to remove the parameter
#
#   * Booleans are written as `on`/`off`.
#   * Arrays are written as an rsyslog array: `["a","b"]`.
#
# @param replace
#   Whether an existing value is replaced
#
#   * `false` only writes the value when the parameter is missing, which is
#     used for fallback values that rsyslog needs to run safely.
#
# @api private
#
define rsyslog::config::param (
  String[1]                                     $block,
  String[1]                                     $header,
  String[1]                                     $key,
  Variant[Boolean, Numeric, String, Array[String[1]]] $value,
  Boolean                                       $replace = true,
) {
  assert_private()

  $_value = $value ? {
    Array   => "[${value.map |$x| { "\"${x}\"" }.join(',')}]",
    default => "\"${rsyslog::format_value($value)}\"",
  }

  $_ensure = $value ? {
    'absent' => 'absent',
    default  => 'present',
  }

  rsyslog::config::line { "${block} ${key}":
    ensure  => $_ensure,
    path    => "${rsyslog::rule_dir}/00_simp_pre_logging/${block}.conf",
    line    => "  ${key}=${_value}",
    match   => "^\\s*${regexpescape($key)}\\s*=",
    after   => "^${regexpescape($header)}\\s*$",
    replace => $replace,
    require => Rsyslog::Config::Block[$block],
  }
}
