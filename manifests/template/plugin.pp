# == Define: rsyslog::template::plugin
#
# This define allows you to add template plugins to the rsyslog configuration
# file.  These rules should be uniquely named.
#
# Note: Plugins are as-is, meaning you'll only supply the plugin name and assume
# that the plugin has already been loaded by RSyslog.
#
# Example:
#   rsyslog::template::string { 'example_plugin':
#     $plugin => 'my_plugin'
#   }
#
# Will produce the following in /etc/rsyslog.simp.d/05_simp_templates/example_plugin.conf:
#   template(name="example_plugin" type="plugin" plugin="my_plugin")
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#   Note: Do not use a '/' in the $name.
#
# [*plugin*]
#   The rsyslog plugin content that you wish to add to the system.
#   This is fed, without formatting, directly into the target file.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
define rsyslog::template::plugin (
  $plugin,
) {
  validate_string($plugin)

  file { "/etc/rsyslog.simp.d/05_simp_templates/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => "template(name=\"${name}\" plugin=\"string\" plugin=\"${plugin}\")",
    notify  => Service['rsyslog']
  }
}
