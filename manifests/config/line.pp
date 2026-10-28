# @summary Manage a single line in a SIMP-owned rsyslog configuration file
#
# Declare this only for settings that are set: an undef parameter means
# "leave the line alone". `ensure => absent` removes the line.
#
# @param path
#   The file holding the line
#
# @param line
#   The full line to write
#
# @param match
#   A regular expression matching every form of the line, so that a changed
#   value replaces the old line instead of adding a second one
#
# @param ensure
#   Whether the line should be present
#
# @param after
#   A regular expression matching the line to insert a new line after
#
#   * Used to place parameters inside a `module(...)`, `global(...)` or
#     `main_queue(...)` block.
#
# @param replace
#   Whether an existing line matching `$match` is replaced
#
#   * `false` only adds the line when no matching line exists, which is used
#     for fallback values that rsyslog needs to run safely.
#
# @api private
#
define rsyslog::config::line (
  Stdlib::Absolutepath      $path,
  String[1]                 $line,
  String[1]                 $match,
  Enum['present', 'absent'] $ensure  = 'present',
  Optional[String[1]]       $after   = undef,
  Boolean                   $replace = true,
) {
  assert_private()

  $_extra = $ensure ? {
    'absent' => { 'match_for_absence' => true },
    default  => { 'after' => $after, 'replace' => $replace },
  }

  file_line { "rsyslog ${title}":
    ensure  => $ensure,
    path    => $path,
    line    => $line,
    match   => $match,
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
    *       => $_extra,
  }
}
