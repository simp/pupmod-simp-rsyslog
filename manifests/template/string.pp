# == Define: rsyslog::template::string
#
# This define allows you to add template strings to the rsyslog configuration
# file.  These rules should be uniquely named.
#
# You'll need to write the entire template line due to the complexity of the
# rsyslog configuration parameters.  Leading spaces will be removed.
#
# Example:
#   rsyslog::template::string { 'example':
#     $content => '/var/log/hosts/%HOSTNAME%/example.log'
#   }
#
# Will produce the following in 05_simp_templates/example.conf:
#   template(name="example" type="string" string="/var/log/hosts/%HOSTNAME%/example.log")
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#   Note: Do not use a '/' in the $name.
#
# [*string*]
#   The rsyslog template string that you wish to add to the system.
#   This is fed, without formatting, directly into the target file.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
define rsyslog::template::string (
  $string,
) {
  validate_string($string)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
    content => "template(name=\"${_safe_name}\" type=\"string\" string=\"${string}\")"
  }
}
