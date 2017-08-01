# Add a template list to the rsyslog configuration file.
#
# RSyslog list templates can contain properties and constants. In order to
# capture this functionality, we have opted for making a hash of these. The
# Hash will be ordered as given to the content variable.
#
# @example Content Settings
#   $content_hash = {
#     'constant' => 'values="Syslog MSG is: \'"',
#     'property' => 'name="msg"'
#   }
#
#   rsyslog::template::list { 'example_list':
#     $content => $content_hash
#   }
#
#   ### Produces:
#
#   template(name="example_list" type="list") {
#     constant(value="Syslog MSG is: '")
#     property(name="msg")
#   }
#
# @param name [String]
#   The literal name (not path) of the ``file`` that will be written
#
# @param content
#   The rsyslog list content that you wish to add to the system, as a Hash
#
define rsyslog::template::list (
  Hash[String,String,1] $content
) {
  $_safe_name = regsubst($name,'/','__')

  $_content = join(map($content) |$key, $value| { "${key}(${value})" }, "\n  ")

  rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
    # lint:ignore:variables_not_enclosed
    content => @("EOM")
      template(name="${name}" type="list") {
        $_content
      }
      |EOM
    # lint:endignore
  }
}
