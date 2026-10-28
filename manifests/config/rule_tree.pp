# @summary Create `$rsyslog::rule_dir` and make rsyslog read it
#
# Included whenever the module writes anything under `$rsyslog::rule_dir`.
#
# * With `rsyslog::config::replace_rsyslog_conf` set to `true`,
#   `/etc/rsyslog.conf` is replaced with one that includes only
#   `$rsyslog::rule_dir`.
# * Otherwise, a single `$IncludeConfig` line for `$rsyslog::rule_dir` is
#   added to the existing `/etc/rsyslog.conf`, after the line that includes
#   `/etc/rsyslog.d` (in either syntax), or at the end of the file when there
#   is none. An existing line is left where it is, so a site can move it, for
#   example ahead of its own rules. Nothing else in the file is changed.
#
# @api private
#
class rsyslog::config::rule_tree {
  assert_private()

  include 'rsyslog'

  $purge_attributes = $rsyslog::config::purge_rule_dir ? {
    true    => { 'recurse' => true, 'purge' => true, 'force' => true },
    default => {},
  }

  file { $rsyslog::rule_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
    *       => $purge_attributes,
  }

  $_include = "\$IncludeConfig ${rsyslog::rule_dir}/*.conf"

  if $rsyslog::config::replace_rsyslog_conf {
    $_custom_conf_content = $rsyslog::config::custom_conf_content ? {
      undef   => '',
      default => "${rsyslog::config::custom_conf_content}\n",
    }

    $_rsyslog_conf = @("RSYSLOG_CONF"/$)
      # This file is managed by Puppet (simp/rsyslog module).
      # Any changes will be overwritten.
      ${_include}
      | RSYSLOG_CONF

    file { '/etc/rsyslog.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => "${_rsyslog_conf}${_custom_conf_content}",
      require => Class['rsyslog::install'],
      notify  => Class['rsyslog::service'],
    }
  }
  else {
    rsyslog::config::line { 'rsyslog.conf include rule_dir':
      path  => '/etc/rsyslog.conf',
      line  => $_include,
      match => "^\\\$IncludeConfig\\s+${regexpescape($rsyslog::rule_dir)}/\\*\\.conf\\s*$",
      after => '^\s*(include\(file="/etc/rsyslog\.d/\*\.conf"|\$IncludeConfig\s+/etc/rsyslog\.d/\*\.conf)',
    }
  }
}
