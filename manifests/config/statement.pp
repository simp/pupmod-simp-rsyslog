# @summary Manage one rsyslog statement (`global(...)`, `module(...)` or `main_queue(...)`) in `00_simp_pre_logging`
#
# The statement's file is created when it is needed and never rewritten. Each
# parameter is then managed on its own line, so that every setting can be
# enforced or left alone independently:
#
# * An undef value leaves the parameter alone.
# * A value sets it, replacing any earlier value.
# * `absent` removes it.
#
# @param header
#   The first line of the statement, e.g. `module(load="imuxsock"`
#
# @param params
#   The parameters to manage, by rsyslog parameter name
#
# @param fallbacks
#   Parameters written only when the file has no value for them yet
#
#   * Used for values rsyslog needs to run safely. A matching key in
#     `$params` takes precedence.
#
# @param create
#   Create the file even when no parameter is set
#
#   * Used for module loads that a replaced `/etc/rsyslog.conf` needs.
#
# @param ensure
#   `absent` removes the whole statement
#
# @api private
#
define rsyslog::config::statement (
  String[1]                 $header,
  Hash[String[1], Any]      $params    = {},
  Hash[String[1], Any]      $fallbacks = {},
  Boolean                   $create    = false,
  Enum['present', 'absent'] $ensure    = 'present',
) {
  assert_private()

  $_params = $params.filter |$k, $v| { $v =~ NotUndef }
  $_fallbacks = $fallbacks.filter |$k, $v| { $v =~ NotUndef and !($k in $_params) }

  $_removals = $_params.filter |$k, $v| { $v == 'absent' }
  $_settings = $_params - $_removals

  if $ensure == 'absent' {
    rsyslog::config::block { $title:
      ensure => 'absent',
      seed   => '',
    }
  }
  elsif !$create and empty($_settings) and empty($_fallbacks) and
  (empty($_removals) or !("${title}.conf" in rsyslog::existing_pre_logging())) {
    # Nothing to set, and nothing to remove from a file that exists
  }
  else {
    rsyslog::config::block { $title:
      seed => "${header}\n)\n",
    }

    $_params.each |$key, $value| {
      rsyslog::config::param { "${title} ${key}":
        block  => $title,
        header => $header,
        key    => $key,
        value  => $value,
      }
    }

    $_fallbacks.each |$key, $value| {
      rsyslog::config::param { "${title} ${key}":
        block   => $title,
        header  => $header,
        key     => $key,
        value   => $value,
        replace => false,
      }
    }
  }
}
