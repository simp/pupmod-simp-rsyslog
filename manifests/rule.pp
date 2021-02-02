# @summary Adds a rule
#
# This is used by the various ``rsyslog::rule::*`` Defined Types to apply rules
# to the system.
#
# Feel free to use this Defined Type to add your own rules but remember that
# **order matters**!
#
# In general, the order will be:
#
#   * 05 - Data Source Rules
#   * 06 - Console Rules
#   * 07 - Drop Rules
#   * 10 - Remote Rules
#   * 20 - Other/Miscellaneous Rules
#   * 99 - Local Rules
#
# @example Collect All ``kern.err`` Messages
#   rsyslog::rule { '99_collect_kernel_errors.conf':
#     rule =>  "if prifilt('kern.err') then /var/log/kernel_errors.log"
#   }
#
# @example Discard All ``info`` Messages
#   rsyslog::rule::other { '98_discard_info.conf':
#     rule =>  "if prifilt('*.info') then stop"
#   }
#
# @param name [Pattern['^[^/]\S+/\S+\.conf$']]
#   The filename that you will be dropping into place
#
#   * **WARNING:** This must **NOT** be an absolute path!
#
# @param content
#   The **exact content** of the rule to place in the target file
#
# @see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-viewing_and_managing_log_files#s1-basic_configuration_of_rsyslog.html Red Hat Basic Rsyslog Configuration
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/expressions.html Expressions in Rsyslog
#
# @see https://www.rsyslog.com/doc/v8-stable/rainerscript/index.html RainerScript Documentation
#
define rsyslog::rule (
  String $content
) {
  if $name !~ Pattern['^[^/]\S+/\S+\.conf$'] {
    fail('The $name must be a valid un-pathed configuration file')
  }
  if !empty(grep([$name],'/.*/')) {
    fail('Error: You cannot have two slashes in the $name')
  }

  include 'rsyslog'

  $_name_array = split($name,'/')
  $_base_directory = "${rsyslog::rule_dir}/${_name_array[0]}"

  if !defined(File[$_base_directory]) {
    # Be sure to notify on directory changes so that rsyslog service
    # is restarted when rules are removed.
    file { $_base_directory:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      recurse => true,
      purge   => true,
      force   => true,
      mode    => '0640',
      notify  => Class['rsyslog::service']
    }
  }

  if !defined(File["${_base_directory}.conf"]) {
    file { "${_base_directory}.conf":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => "\$IncludeConfig ${_base_directory}/*.conf\n",
      notify  => Class['rsyslog::service']
    }
  }

  file { "${rsyslog::rule_dir}/${name}":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $content,
    notify  => Class['rsyslog::service']
  }
}
