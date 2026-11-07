# @summary Create a numbered rule subdirectory under `$rsyslog::rule_dir`
#
# Creates the directory and the `<name>.conf` file that includes it.
#
# The directory is purged only when `rsyslog::config::purge_rule_dir` is
# `true`.
#
# For `00_simp_pre_logging`, this also removes the `global.conf` that versions
# before 11.0.0 wrote. It holds the same statements as the files that replace
# it, and rsyslog rejects a module loaded twice.
#
# @api private
#
define rsyslog::rule::directory {
  assert_private()

  include 'rsyslog::config::rule_tree'

  $_base_directory = "${rsyslog::rule_dir}/${name}"

  # Be sure to notify on directory changes so that rsyslog service
  # is restarted when rules are removed.
  file { $_base_directory:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    notify => Class['rsyslog::service'],
    *      => $rsyslog::config::rule_tree::purge_attributes,
  }

  file { "${_base_directory}.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => "\$IncludeConfig ${_base_directory}/*.conf\n",
    notify  => Class['rsyslog::service'],
  }

  if $name == '00_simp_pre_logging' {
    file { "${_base_directory}/global.conf":
      ensure => 'absent',
      notify => Class['rsyslog::service'],
    }

    include 'rsyslog::config::pre_logging'
  }
}
