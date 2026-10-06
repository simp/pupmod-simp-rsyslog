# @summary Load the input modules in `00_simp_pre_logging`
#
# Included whenever anything is written to `00_simp_pre_logging`, which also
# removes the `global.conf` that versions before 11.0.0 wrote there.
#
# * When `/etc/rsyslog.conf` is this module's (`rsyslog::config::simp_conf`),
#   it includes only the rule directory, so `imklog`, `imuxsock`,
#   `imjournal` (unless `rsyslog::config::read_journald` is `false`) and
#   `imfile` are loaded here. `global.conf` loaded them before 11.0.0.
# * Otherwise the package's `/etc/rsyslog.conf` loads `imuxsock` and
#   `imjournal`, and `imklog` and `imfile` are loaded here only when their
#   `extra_*_mod_params` are set.
#
# @api private
#
class rsyslog::config::pre_logging {
  assert_private()

  include 'rsyslog'

  if $rsyslog::config::simp_conf or $rsyslog::config::extra_imklog_mod_params =~ NotUndef {
    rsyslog::config::statement { '30_imklog':
      header => 'module(load="imklog"',
      params => pick($rsyslog::config::extra_imklog_mod_params, {}),
      create => true,
    }
  }

  if $rsyslog::config::simp_conf {
    rsyslog::config::statement { '31_imuxsock':
      header => 'module(load="imuxsock"',
      params => {
        'SysSock.IgnoreTimestamp'    => $rsyslog::config::syssock_ignore_timestamp,
        'SysSock.IgnoreOwnMessages'  => $rsyslog::config::syssock_ignore_own_messages,
        'SysSock.Use'                => $rsyslog::config::syssock_use,
        'SysSock.Name'               => $rsyslog::config::syssock_name,
        'SysSock.FlowControl'        => $rsyslog::config::syssock_flow_control,
        'SysSock.UsePIDFromSystem'   => $rsyslog::config::syssock_use_pid_from_system,
        'SysSock.RateLimit.Interval' => $rsyslog::config::syssock_rate_limit_interval,
        'SysSock.RateLimit.Burst'    => $rsyslog::config::syssock_rate_limit_burst,
        'SysSock.RateLimit.Severity' => $rsyslog::config::syssock_rate_limit_severity,
        'SysSock.UseSysTimeStamp'    => $rsyslog::config::syssock_use_sys_timestamp,
        'SysSock.Annotate'           => $rsyslog::config::syssock_annotate,
        'SysSock.ParseTrusted'       => $rsyslog::config::syssock_parse_trusted,
        'SysSock.Unlink'             => $rsyslog::config::syssock_unlink,
      } + pick($rsyslog::config::extra_imuxsock_mod_params, {}),
      create => true,
    }

    # Without imjournal, a module-owned rsyslog.conf reads nothing from the
    # journal, so it is loaded unless read_journald is false.
    rsyslog::config::statement { '32_imjournal':
      ensure    => bool2str($rsyslog::config::read_journald == false, 'absent', 'present'),
      header    => 'module(load="imjournal"',
      params    => pick($rsyslog::config::extra_imjournal_mod_params, {}),
      fallbacks => { 'StateFile' => 'imjournal.state' },
      create    => true,
    }
  }

  if $rsyslog::config::simp_conf or $rsyslog::config::extra_imfile_mod_params =~ NotUndef {
    include 'rsyslog::config::imfile'
  }
}
