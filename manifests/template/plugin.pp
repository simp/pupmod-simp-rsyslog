# @summary Add template plugins to the rsyslog configuration file.
#
# **NOTE:** Plugins are **as-is**. This means that you will only supply the
# plugin name and assume that the plugin has already been loaded by RSyslog.
#
# @example Adding the ``my_plugin`` Plugin to the System
#   rsyslog::template::string { 'example_plugin':
#     $plugin => 'my_plugin'
#   }
#
#   ### Produces:
#
#   template(name="example_plugin" type="plugin" plugin="my_plugin")
#
# @param name [String]
#   The literal name of the ``file`` (not the full path) that will be used
#
# @param plugin
#   The rsyslog plugin content that you wish to add to the system
#
#   * Required unless `$ensure` is `absent`.
#   * This is provided, without formatting, directly into the target file
#
# @param ensure
#   `absent` removes the rule file
#
define rsyslog::template::plugin (
  Optional[String]          $plugin = undef,
  Enum['present', 'absent'] $ensure = 'present',
) {
  $_safe_name = regsubst($name,'/','__')

  if $ensure == 'absent' {
    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      ensure => 'absent',
    }
  }
  else {
    if $plugin =~ Undef {
      fail('$plugin is required unless $ensure is absent')
    }

    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      # lint:ignore:double_quoted_strings lint:ignore:only_variable_string
      content => @("EOM")
        template(name="${_safe_name}" plugin="string" plugin="${plugin}")
        |EOM
      # lint:endignore
    }
  }
}
