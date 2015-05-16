# == Define: rsyslog::add_rule
#
# This define allows you to add rules to the rsyslog configuration file.
# These rules should be uniquely named.
#
# The variables listed are as defined in the rsyslog.conf(5) man page for rules
# (not globals).
#
# You'll need to write the entire rule due to the complexity of the rsyslog
# configuration parameters.  Leading spaces will be removed.
#
# Please note that the stock rsyslog remote server makes use of the '0$name'
# space so please avoid using that space unless you are extending the server
# configuration.
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#   Note: Do not use a '/' in the $name.
#
# [*rule*]
#   The rsyslog rule that you wish to add to the system.
#   This is fed, without formatting, directly into the target file.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define rsyslog::add_rule (
  $rule
) {
  concat_fragment { "rsyslog+$name.rule":
    content => inline_template('<%= @rule.split("\n").collect{ |x| x.sub(/^\s+/,"") }.join("\n") + "\n" %>')
  }
}
