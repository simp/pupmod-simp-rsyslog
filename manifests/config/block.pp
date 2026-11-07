# @summary Create a file in `00_simp_pre_logging` that holds one rsyslog statement
#
# The file is created with `$seed` only when it does not exist yet, and is
# never rewritten afterwards. Each parameter inside the statement is then
# managed separately with `rsyslog::config::line`, so a parameter that a later
# run leaves unset keeps its value.
#
# @param seed
#   The content the file is created with, for example
#   `module(load="imuxsock"\n)\n`
#
# @param ensure
#   Whether the file should exist
#
# @api private
#
define rsyslog::config::block (
  String                    $seed,
  Enum['present', 'absent'] $ensure = 'present',
) {
  assert_private()

  $_path = "${rsyslog::rule_dir}/00_simp_pre_logging/${title}.conf"

  if $ensure == 'absent' {
    file { $_path:
      ensure => 'absent',
      notify => Class['rsyslog::service'],
    }
  }
  else {
    include 'rsyslog::config::rule_tree'

    ensure_resource('rsyslog::rule::directory', '00_simp_pre_logging')

    file { $_path:
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $seed,
      replace => false,
      require => Class['rsyslog::install'],
      notify  => Class['rsyslog::service'],
    }
  }
}
