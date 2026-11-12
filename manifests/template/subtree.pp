# @summary Add template subtrees to the rsyslog configuration
#
# You'll need to write the entire subtree line due to the complexity of the
# rsyslog configuration parameters.
#
# @example Subtree (From the Official RSyslog Docs)
#   rsyslog::template::subtree { 'example_subtree':
#     $variables => ['$!usr!tp12!msg = $msg;', '$!usr!tp12!dataflow = field($msg, 58, 2);'],
#     $subtree   => '$!usr!tp12'
#   }
#
#   ### Produces:
#
#   set $!usr!tp12!msg = $msg;
#   set $!usr!tp12!dataflow = field($msg, 58, 2);
#   template(name="example" type="subtree" subtree="$!usr!tp12")
#
# @param name [String]
#   The literal name of the ``file`` (not a path) that will be used
#
# @param subtree
#   The rsyslog subtree content that you wish to add to the system
#
#   * Required unless `$ensure` is `absent`.
#   * This is fed, without formatting, directly into the subtree parameter
#
# @param variables
#   Variables to be set **prior** to the template being created
#
# @param ensure
#   `absent` removes the rule file
#
define rsyslog::template::subtree (
  Optional[String]          $subtree   = undef,
  Array[String]             $variables = [],
  Enum['present', 'absent'] $ensure    = 'present',
) {
  $_safe_name = regsubst($name,'/','__')

  if $ensure == 'absent' {
    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      ensure => 'absent',
    }
  }
  else {
    if $subtree =~ Undef {
      fail('$subtree is required unless $ensure is absent')
    }

    $_variables = join($variables,"\n")

    rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
      # lint:ignore:variables_not_enclosed
      content => @("EOM")
        $_variables

        template(name="${name}" type="subtree" subtree="${subtree}")
        |EOM
      # lint:endignore
    }
  }
}
