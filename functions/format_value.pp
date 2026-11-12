# @summary Render a parameter value the way rsyslog expects it
#
# Booleans become `on`/`off`; everything else is rendered as a String.
#
# @param value
#   The value to render
#
# @return [String]
#
# @api private
#
function rsyslog::format_value(
  Variant[Boolean, Numeric, String] $value,
) >> String {
  $value ? {
    true    => 'on',
    false   => 'off',
    default => String($value),
  }
}
