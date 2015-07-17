# == Define: rsyslog::template
#
# This define allows you to add template strings to the rsyslog configuration
# file.  These rules should be uniquely named.
#
# You'll need to write the entire template line due to the complexity of the
# rsyslog configuration parameters.  Leading spaces will be removed.
#
# == Parameters
#
# [*name*]
#   The literal name of the file that will be used to build the multi-part
#   file.
#   Note: Do not use a '/' in the $name.
#
# [*content*]
#   The rsyslog template content that you wish to add to the system.
#   This is fed, without formatting, directly into the target file.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Mike Riddle <mailto:mriddle@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
define rsyslog::template (
  $content,
) {
  concat_fragment { "rsyslog_templates+$name.template":
    content => "\$template $name,\"$content\"\n"
  }
}
