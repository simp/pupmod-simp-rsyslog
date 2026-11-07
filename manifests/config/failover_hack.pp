# @summary Add the no-op rule that rsyslog needs before any failover action
#
# Rsyslog does not parse a failover action definition unless at least one rule
# already exists, so this places a no-op rule ahead of the remote rules.
#
# @api private
#
class rsyslog::config::failover_hack {
  assert_private()

  rsyslog::rule { '09_failover_hack/failover_hack.conf':
    # lint:ignore:variable_scope
    content => @(EOM)
      # For failover to be defined and parse properly, we must place it somewhere
      # after the first rule is defined. Therefore, we are creating this noop rule.

      if $syslogfacility == 'local0' and $msg startswith 'placeholder_rule' then continue
      |EOM
    # lint:endignore
  }
}
