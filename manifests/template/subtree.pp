# == Define: rsyslog::template::subtree
#
# This define allows you to add template subtrees to the rsyslog configuration
# file.  These rules should be uniquely named.
#
# You'll need to write the entire subtree line due to the complexity of the
# rsyslog configuration parameters.
#
# Example: (Adapted from the RSyslog official documentation)
#   rsyslog::template::subtree { 'example_subtree':
#     $variables => ['$!usr!tp12!msg = $msg;', '$!usr!tp12!dataflow = field($msg, 58, 2);'],
#     $subtree   => '$!usr!tp12'
#   }
#
# Will produce the following in 05_simp_templates/example_subtree.conf:
#   set $!usr!tp12!msg = $msg;
#   set $!usr!tp12!dataflow = field($msg, 58, 2);
#   template(name="example" type="subtree" subtree="$!usr!tp12")
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#   Note: Do not use a '/' in the $name.
#
# [*subtree*]
#   The rsyslog subtree content that you wish to add to the system.
#   This is fed, without formatting, directly into the subtree parameter.
#
# [*variables*]
#   An array of variables to be set prior to the template being created.
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
define rsyslog::template::subtree (
  $subtree,
  $variables = []
) {
  validate_string($subtree)
  validate_array($variables)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
    content => inline_template(
'<%= @variables.join("\n") %>
template(name="<%= @name %>" type="subtree" subtree="<%= @subtree %>"'
    )
  }
}
