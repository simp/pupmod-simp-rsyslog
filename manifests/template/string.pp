# @summary Add template strings to the rsyslog configuration
#
# You'll need to write the entire template line due to the complexity of the
# rsyslog configuration parameters.
#
# Leading spaces will be removed.
#
# @example Template String
#   rsyslog::template::string { 'example':
#     $content => '/var/log/hosts/%HOSTNAME%/example.log'
#   }
#
#   ### Produces:
#
#   template(name="example" type="string" string="/var/log/hosts/%HOSTNAME%/example.log")
#
# @param name [String]
#   The literal name of the ``file`` (not file path) that will be used
#
# @param string
#   The rsyslog template string that you wish to add to the system
#
#   * Required unless `$ensure` is `absent`.
#   * This is fed, without formatting, directly into the target file
#
# @param ensure
#   `absent` removes the rule file
#
define rsyslog::template::string (
  Optional[String]          $string = undef,
  Enum['present', 'absent'] $ensure = 'present',
) {
  $_safe_name = regsubst($name,'/','__')

  if $ensure == 'absent' {
    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      ensure => 'absent',
    }
  }
  else {
    if $string =~ Undef {
      fail('$string is required unless $ensure is absent')
    }

    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      # lint:ignore:double_quoted_strings lint:ignore:only_variable_string
      content => @("EOM")
        template(name="${_safe_name}" type="string" string="${string}")
        |EOM
      #lint:endignore
    }
  }
}
