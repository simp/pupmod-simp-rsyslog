# == Define: rsyslog::rule
#
# A generic define for creating rsyslog rules.
#
# This adds a configuration file to the /etc/rsyslog.simp.d directory.
#
# == Parameters
#
# [*name*]
#   The target for the rule file.
#   Must have the form base_directory/filename.conf
#   This must *not* be an absolute path. The base_directory will be relative to
#   $::rsyslog::rule_dir
#
# [*content*]
#   The exact content of the rule to place in the target file.
#
define rsyslog::rule (
  $content
) {
  validate_re($name,'^[^/]\S+/\S+\.conf$')
  if !empty(grep([$name],'/.*/')) {
    fail('Error: You cannot have two slashes in the $name')
  }
  validate_string($content)

  include '::rsyslog'

  $_name_array = split($name,'/')
  $_base_directory = "${::rsyslog::rule_dir}/${_name_array[0]}"

  if !defined(File[$_base_directory]) {
    file { $_base_directory:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      recurse => true,
      purge   => true,
      force   => true,
      mode    => '0640'
    }
  }

  if !defined(File["${_base_directory}.conf"]) {
    file { "${_base_directory}.conf":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => "\$IncludeConfig ${_base_directory}/*.conf"
    }
  }

  file { "${::rsyslog::rule_dir}/${name}":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $content,
    notify  => Class['rsyslog::service']
  }
}
