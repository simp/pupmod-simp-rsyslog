#== Define: rsyslog::add_conf
#
# This adds a configuration file to the /etc/rsyslog.d directory.  Take care,
# as these are processed prior to any other rules running.
#
# This will *not* add a target that is the system that it is being evaluated
# on. This is to prevent syslog loops that will quickly destroy your systems.
#
# Unfortunately, this is not perfect.  We cannot detect if you use a DNS
# alias to the host instead of the true hostname.
#
# == Parameters
#
# [*name*]
#   The filename that you will be dropping into place.
#   Note: Do not include a '/' in the name.
#
# [*content*]
#   The literal content of the file that you are placing in the
#   /etc/rsyslog.d directory.
#
# [*dest*]
#   Type: Array of destination targets
#   Default []
#     If filled, the _$content_ above will be sent to all entries in this
#     array.
#
#     If using this, do NOT add a destination to your content above!
#
#   Example:
#     ['syslog1.my.network','syslog2.my.network']
#
# [*dest_type*]
#   Type: 'tcp','udp', or 'relp'
#   Default: 'tcp'
#     The destination type for all entries in _$dest_ above. At this
#     time, if you wish to have different types per destination, you
#     will need to craft your own full rule set and leave _$dest_
#     empty.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::add_conf (
  $content,
  $dest = [],
  $dest_type = 'tcp'
) {

  $prefix = {
    'tcp'  => '@@',
    'udp'  => '@',
    'relp' => ':omrelp:'
  }

  file { "/etc/rsyslog.d/puppet_managed/${name}.conf":
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => empty($dest) ? {
      true  => $content,
      false => inline_template('
<% t_dest = @dest.dup -%>
<% if not (t_dest.length.eql?(1) and scope.function_host_is_me(t_dest)) -%>
$RepeatedMsgReduction off
<%= @content %>     <%= @prefix[@dest_type] %><%= t_dest.shift %>
$ActionExecOnlyWhenPreviousIsSuspended on
<%   t_dest.each do |dest| -%>
<%     if not scope.function_host_is_me([dest]) -%>
& <%= @prefix[@dest_type] %><%= dest %>
<%     end -%>
<%   end -%>
$ActionExecOnlyWhenPreviousIsSuspended off
$RepeatedMsgReduction on
<% end -%>
')
    },
    notify  => Service['rsyslog']
  }

  validate_array($dest)
  validate_array_member($dest_type,['tcp','udp','relp'])
}
