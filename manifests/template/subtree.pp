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
# Will produce the following in /etc/rsyslog.simp.d/05_simp_templates/example_subtree.conf:
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

  file { "/etc/rsyslog.simp.d/05_simp_templates/${name}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => inline_template(
'<%= @variables.join("\n") %>
template(name="<%= @name %>" type="subtree" subtree="<%= @subtree %>"'
    ),
    notify  => Service['rsyslog']
  }
}
