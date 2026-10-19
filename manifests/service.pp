# @summary Manage the RSyslog service
#
# The service is managed only when `rsyslog::service_ensure` or
# `rsyslog::service_enable` is set. Otherwise, with
# `rsyslog::restart_on_change` set, a running rsyslog is restarted when the
# module changes its configuration.
#
# @param enable
#   **DEPRECATED**. Use `rsyslog::service_ensure` and
#   `rsyslog::service_enable` instead.
#
#   * Still used when neither of those is set: `true` keeps the service
#     running and enabled, and `false` stopped and disabled.
#
# @api private
#
class rsyslog::service (
  Optional[Boolean] $enable = undef,
) {
  assert_private()

  if $enable =~ NotUndef {
    deprecation('rsyslog::service::enable',
      'rsyslog::service::enable is deprecated. Use rsyslog::service_ensure and rsyslog::service_enable instead', false)
  }

  $_legacy_ensure = $enable ? {
    true    => 'running',
    false   => 'stopped',
    default => undef,
  }

  if $rsyslog::service_ensure =~ NotUndef or $rsyslog::service_enable =~ NotUndef {
    $_ensure = $rsyslog::service_ensure
    $_enable = $rsyslog::service_enable
  }
  else {
    $_ensure = $_legacy_ensure
    $_enable = $enable
  }

  if $_ensure =~ NotUndef or $_enable =~ NotUndef {
    service { $rsyslog::service_name:
      ensure     => $_ensure,
      enable     => $_enable,
      hasrestart => true,
      hasstatus  => true
    }
  }
  elsif $rsyslog::restart_on_change {
    # Every configuration resource notifies this class, so this runs whenever
    # the module changes the configuration. try-restart does nothing when the
    # service is not running.
    exec { 'rsyslog restart_on_change':
      command     => "systemctl try-restart ${rsyslog::service_name}.service",
      path        => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      refreshonly => true,
    }
  }
}
