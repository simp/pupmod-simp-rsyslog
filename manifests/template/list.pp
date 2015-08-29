# == Define: rsyslog::template::list
#
# This define allows you to add template list to the rsyslog configuration
# file.  These rules should be uniquely named.
#
# RSyslog list templates can contain properties and constants. In order to
# capture this functionality, we have opted for making a hash of these. The
# hash will be ordered as given to the content variable. As an example of this:
#  content      => {
#    'constant' => 'values="Syslog MSG is: \'"',
#    'property' => 'name="msg"'
#  }
#
# Example:
#  $content_hash = {
#    'constant' => 'values="Syslog MSG is: \'"',
#    'property' => 'name="msg"'
#  }
#
#  rsyslog::template::list { 'example_list':
#    $content => $content_hash
#  }
#
# Will produce the following in 05_simp_templates/example_list.conf:
#   template(name="example_list" type="list") {
#     constant(value="Syslog MSG is: '")
#     property(name="msg")
#   }
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#
# [*content*]
#   The rsyslog list content that you wish to add to the system.
#
define rsyslog::template::list (
  $content,
) {
  validate_hash($content)

  $_safe_name = regsubst($name,'/','__')

  rsyslog::rule { "05_simp_templates/${_safe_name}.conf":
    content => inline_template(
'template(name="<%= @name %>" type="list") {
<% @content.each do |k,v| -%>
  <%= k %>(<%= v %>)
<% end -%>
}'
    )
  }
}
