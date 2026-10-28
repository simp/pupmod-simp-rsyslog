#pupmod-simp-rsyslog

[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/rsyslog.svg)](https://forge.puppetlabs.com/simp/rsyslog)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/rsyslog.svg)](https://forge.puppetlabs.com/simp/rsyslog)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-rsyslog.svg)](https://travis-ci.org/simp/pupmod-simp-rsyslog)


#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Overview](#overview)
* [Breaking changes in 11.0.0](#breaking-changes-in-1100)
  * [Restoring the previous behavior](#restoring-the-previous-behavior)
  * [Upgrading without the profile](#upgrading-without-the-profile)
* [This is a SIMP module](#this-is-a-simp-module)
* [Module Description](#module-description)
* [Setup](#setup)
  * [What pupmod-simp-rsyslog affects](#what-pupmod-simp-rsyslog-affects)
  * [Setup Requirements](#setup-requirements)
  * [Beginning with pupmod-simp-rsyslog](#beginning-with-pupmod-simp-rsyslog)
  * [How settings are applied](#how-settings-are-applied)
  * [Applying changes while the service is unmanaged](#applying-changes-while-the-service-is-unmanaged)
* [Usage](#usage)
  * [I want standard remote logging on a client](#i-want-standard-remote-logging-on-a-client)
  * [I want to send everything to rsyslog from a client](#i-want-to-send-everything-to-rsyslog-from-a-client)
  * [I want to disable TLS/PKI/Logrotate](#i-want-to-disable-tlspkilogrotate)
  * [I want to set up an RSyslog Server](#i-want-to-set-up-an-rsyslog-server)
  * [I want to set up an Rsyslog Server without logrotate/pki/firewall](#i-want-to-set-up-an-rsyslog-server-without-logrotatepkifirewall)
  * [Central Log Forwarding](#central-log-forwarding)
  * [Mixed TLS and plain-text forwarding](#mixed-tls-and-plain-text-forwarding)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Overview

[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) configures
and manages RSyslog version 8 as built into either
[RHEL](http://www.redhat.com/en) and compatible distributions.

## Breaking changes in 11.0.0

A bare `include rsyslog` now installs the `rsyslog` package and changes nothing
else. Every other behavior is turned on by a parameter. In particular, a bare
`include` no longer:

* replaces `/etc/rsyslog.conf` (`rsyslog::config::replace_rsyslog_conf`) or
  `/etc/sysconfig/rsyslog` (`rsyslog::config::syslogd_options`);
* purges `/etc/rsyslog.simp.d` and its subdirectories
  (`rsyslog::config::purge_rule_dir`);
* writes the global, module and main queue settings in
  `00_simp_pre_logging` (each `rsyslog::config` parameter, now `undef` by
  default);
* writes SIMP's default logging rules (`rsyslog::config::enable_default_rules`)
  or the systemd `LimitNOFILE` drop-in
  (`rsyslog::config::ulimit_max_open_files`);
* manages the `rsyslog` service (`rsyslog::service_ensure`,
  `rsyslog::service_enable`);
* turns on the `nis_enabled` SELinux boolean on an `rsyslog::server` when
  SELinux is enforcing (`rsyslog::server::enable_selinux`).

`rsyslog::tcp_server`, `rsyslog::tls_tcp_server`, `rsyslog::udp_server` and
`rsyslog::read_journald` now default to `undef`: `true` adds the listener (or
module), `false` removes it, and `undef` leaves it alone. With
`rsyslog::server`, a listener's firewall rule stays while the listener is
configured and its parameter is unset.

The UDP listener now binds to `rsyslog::udp_listen_address` (default
`127.0.0.1`), which 10.x ignored. To receive UDP syslog from other hosts, set
it, for example to `0.0.0.0`.

Features driven by `simp_options::*` (PKI, logrotate, the firewall, the log
servers and trusted networks) still follow those settings.

The global settings that were in `00_simp_pre_logging/global.conf` are now
split into one file per statement, such as `10_global.conf`,
`31_imuxsock.conf` and `90_main_queue.conf`, and each setting is managed on
its own line.

### Restoring the previous behavior

There are two ways to get the 10.x behavior back:

1. **Enforce the `simp:defaults` profile.** This module ships a
   [Compliance Engine](https://github.com/simp/rubygem-simp-compliance_engine)
   profile that restores every 10.x default, including the destructive ones:
   replacing `/etc/rsyslog.conf`, purging `/etc/rsyslog.simp.d`, and managing
   the service. With the `compliance_engine` module installed, set:

   ```yaml
   compliance_engine::enforcement:
     - simp:defaults
   ```

   The profile only fills in parameters that your Hiera does not set, so a
   site that wants the old behavior without a destructive part can override
   that one parameter, for example:

   ```yaml
   compliance_engine::enforcement:
     - simp:defaults
   rsyslog::config::purge_rule_dir: false
   ```

2. **Set the parameters you want** in Hiera, as listed above.

### Upgrading without the profile

With a bare `include`, nothing that 10.x wrote is removed or rewritten on
upgrade: `/etc/rsyslog.conf`, `/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf`
and the rest stay as they are, and rsyslog keeps running with them. Rules
that other modules declare are still written to the rule directory, which the
10.x `/etc/rsyslog.conf` already includes.

The module recognizes the `/etc/rsyslog.conf` that 10.x wrote (through the
`rsyslog_simp_config` fact) and treats it like one written with
`replace_rsyslog_conf`: it includes only the rule directory, so the module
loads `imklog`, `imuxsock`, `imjournal` and `imfile` itself, and the
`work_directory`, `syssock_*` and `default_file_template` settings take
effect.

The first time anything is written to `00_simp_pre_logging` (any global,
module or main queue setting, a TLS rule, or an `rsyslog::rule::data_source`),
the 10.x `global.conf` is removed, because the new files hold the same
statements and rsyslog rejects a module loaded twice. Settings that
`global.conf` held and that are not set again fall back to rsyslog's
defaults. Enforce `simp:defaults` to keep all of them.

## This is a SIMP module

This module is a component of the
[System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net/).

## Module Description

This module follows the standard
[PuppetLabs module style guide](https://puppetlabs.com/guides/style_guide.html)
with some SIMP-specific configuration items included for managing auditing,
firewall rules, logging, and SELinux. All of these items are
configurable and can be turned on or off as needed for each user environment.

[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) was designed
to be as compatible with RSyslog v8-stable as possible, though the version that
comes stock with RHEL or CentOS is slightly dated.

It is possible to use
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) on its own
and configure all rules and settings as you like, but it is recommended that
the [SIMP Rsyslog Profile](https://github.com/simp/pupmod-simp-simp_rsyslog)
be used if possible. By default, this profile will setup security relevant
logging rules and manage server/client configurations.

## Setup

### What pupmod-simp-rsyslog affects

Files managed by
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog), when the
parameters that need them are set:
* /etc/rsyslog.conf (one `$IncludeConfig` line, or the whole file with
  `rsyslog::config::replace_rsyslog_conf`)
* /etc/rsyslog.simp.d
* /etc/sysconfig/rsyslog (the `SYSLOGD_OPTIONS` line)
* /etc/systemd/system/rsyslog.service.d/simp_limits.conf

In addition to these, the `rsyslog::rule::<all>` definitions will create
numbered directories in the `$rsyslog_rule_dir`, by default
`/etc/rsyslog.simp.d`. These directories are included in alphanumeric order and
using the `rsyslog::rule` definition, the user can specify any directory name
they want to impact order.

Services and operations managed or affected by
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* rsyslogd
* auditd (configurable)
* firewall (configurable)
  * NOTE: If firewall management is enabled, and you are using iptables (not
    firewalld), then you MUST set ``iptables::precise_match: true`` in Hiera.
* SELinux (configurable)
* Logrotate (configurable)

Packages installed by
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* rsyslog
* rsyslog-gnutls (only when TLS is used)

### Setup Requirements

It is *strongly* recommended that the logging infrastructure be set up in a
resilient manner. Failover in RSyslog is tricky and choosing the wrong kind of
queuing with failover could mean losing logs. This module attempts to protect
you from that, but will allow you to change the queuing mechanism to meet your
local requirements.

### Beginning with pupmod-simp-rsyslog

Including ``rsyslog`` installs the rsyslog package. Set parameters, or enforce
the `simp:defaults` profile, to configure and start it:

**Puppet Code:**
```puppet
include rsyslog
```

**Hiera Config:**
```yaml
rsyslog::service_ensure: running
rsyslog::service_enable: true
rsyslog::config::net_enable_dns: false
```

Including ``rsyslog::server`` will additionally configure the system as an Rsyslog
server.

**Puppet Code:**
```puppet
include rsyslog::server
```

### How settings are applied

Every setting can be enforced on its own:

* `undef` (the default) leaves the setting alone. Whatever an earlier run,
  another tool or an administrator set stays.
* A value sets it, replacing any earlier value.
* `absent` removes it (`false` for Boolean toggles such as
  `rsyslog::config::enable_default_rules` and the listeners).

Settings are written under `/etc/rsyslog.simp.d/00_simp_pre_logging`, one
line per setting. Rules from `rsyslog::rule` and its wrappers go in the
numbered directories next to it. `rsyslog::rule` and every wrapper accept
`ensure => absent`, which removes a rule without purging the directory.

How rsyslog reads `/etc/rsyslog.simp.d` depends on
`rsyslog::config::replace_rsyslog_conf`:

* `false` (the default): the module adds one line,
  `$IncludeConfig /etc/rsyslog.simp.d/*.conf`, to the package's
  `/etc/rsyslog.conf`, after its `/etc/rsyslog.d` include. SIMP's settings and
  rules then come after any `/etc/rsyslog.d` files and before the package's
  own logging rules, so SIMP's drop rules apply to them.

  The package's `/etc/rsyslog.conf` already sets `workDirectory` and loads the
  `imuxsock`, `imjournal` and `omfile` modules, and rsyslog rejects a second
  value for them. The parameters for those settings (`work_directory`,
  `syssock_*`, `read_journald`, `default_file_template` and their `extra_*`
  hashes) only warn in this mode. Set them in `/etc/rsyslog.conf` yourself, or
  use `replace_rsyslog_conf`.
* `true`: `/etc/rsyslog.conf` is replaced by one that includes only
  `/etc/rsyslog.simp.d`, and the module loads the `imklog`, `imuxsock`,
  `imjournal` and `imfile` modules itself. This discards the package's logging
  rules, so SIMP's default rules (`rsyslog::config::enable_default_rules`) are
  written if they are missing: rsyslog does not start without any rule.
  `enable_default_rules: false` opts out.

If the package's `/etc/rsyslog.conf` has no line including `/etc/rsyslog.d`,
the `$IncludeConfig` line is added at the end of the file, after the package's
rules. The module leaves an existing line where it is, so you can move it
ahead of your rules.

Rule file names never contain `hostname` (it is written as `host_name`): the
SELinux policy labels `/etc/.*hostname.*` files `hostname_etc_t`, which
rsyslog cannot read on EL10. For the same reason, don't use a `rule_dir` with
`hostname` in its path.

A few settings that rsyslog needs to run safely are written, when they are
missing, even if their parameter is unset: the TLS stream driver and
certificate paths when TLS is in use, `StreamDriver.AuthMode` and
`PermittedPeer` for a TLS listener, and, when `/etc/rsyslog.conf` is this
module's, `workDirectory` (`/var/spool/rsyslog`) and imjournal's `StateFile`. An explicit value replaces them, and
`absent` removes them.

### Applying changes while the service is unmanaged

When `rsyslog::service_ensure` and `rsyslog::service_enable` are both unset,
the module writes configuration but does not restart rsyslog, so changes take
effect the next time it restarts. To apply them by hand:

```sh
rsyslogd -N1 && systemctl restart rsyslog
```

Set `rsyslog::restart_on_change: true` to have the module run
`systemctl try-restart rsyslog` whenever it changes the configuration. This
never starts, stops, enables or disables the service.

## Usage

The examples below assume that the `simp:defaults` profile is enforced, or
that the service and other settings you need are set as described above.

pupmod-simp-rsyslog is meant to be extremely customizable, and as such there is
no single best way to use it. For the SIMP specific recommendations on how to
use RSyslog (and other modules as well), check out the
[SIMP profile](https://github.com/simp/pupmod-simp-simp_rsyslog).

### I want standard remote logging on a client

An example of an RSyslog client configuration may look like the following,
including possible file names and a simple remote rule to forward all logs on
the system.

**Hiera Config:**
```yaml
# Send to *all* of these servers!
log_servers:
  - 'first.log.server'
  - 'second.log.server'
failover_log_servers:
  - 'first-failover.log.server'
  - 'second-failover.log.server'
```

**Puppet Code:**
```puppet
include rsyslog
```

### I want to send everything to rsyslog from a client

**NOTE**: Everything must be in the form that would be in the middle of an
``if/then`` Rainerscript Expression.

For example, if you wanted to filter on the standard priority ``kern.err``, you
would put ``prifilt('kern.err')`` in your ``rule`` parameter.

This does **not** hold for a call to ``rsyslog::rule`` since that is the
generic processor for all rules.

**Hiera Config:**
```yaml
rsyslog::log_servers:
  - 'first.log.server'
  - 'second.log.server'

rsyslog::failover_log_servers:
  - 'first.log.server'
  - 'second.log.server'
```

**Puppet Code:**
```puppet
class my_rsyslog_client {
  rsyslog::rule::remote { 'send_the_logs':
    rule => 'prifilt(\'*.*\')'
  }
}
```

### I want to disable TLS/PKI/Logrotate

**Hiera Config:**
```yaml
rsyslog::log_servers:
  - 'first.log.server'
  - 'second.log.server'

rsyslog::failover_log_servers:
  - 'first.log.server'
  - 'second.log.server'

rsyslog::enable_tls_logging: false
rsyslog::logrotate: false
rsyslog::pki: false
```

### I want to set up an RSyslog Server

**Hiera Config:**
```yaml
rsyslog::log_servers:
  - 'first.log.server'
  - 'second.log.server'

rsyslog::failover_log_servers:
  - 'first.log.server'
  - 'second.log.server'
```

**Puppet Code:**
```puppet
class my_rsyslog_server {
  include rsyslog::server

  rsyslog::template::string { 'store_the_logs':
    string => '/var/log/hosts/%HOSTNAME%/everything.log'
  }
}
```

Using the above, all possible logs sent from the client will be stored on the
server in a single log file. Obviously, this is not always an effective
strategy, but it is at least enough to get started. Further customizations can
be built to help manage more logs appropriately. To learn more about how to use
the templates and rules, feel free to browse through the code.

While this setup does cover all of the basics, using the SIMP suggested RSyslog
profile will setup templates and a large set of default rules to help organize
and send logs where possible. Included would also be a comprehensive set of
security relevant logs to help filter important information.

### I want to set up an Rsyslog Server without logrotate/pki/firewall

**Hiera Config:**
```yaml
  rsyslog::logrotate: false
  rsyslog::server::enable_firewall: false
  rsyslog::server::enable_selinux: false
```

### Central Log Forwarding

Following on from the first example, you may have an upstream server to which
you want to send all logs from your collected hosts.

To do this, you would use a manifest similar to the following on your local log
server to forward everything upstream. Note, the use of a custom template.
Upstream systems may have their own requirements and this allows you to
manipulate the log appropriately prior to forwarding the message along.

**Puppet Code:**
```puppet
rsyslog::template::string { 'upstream':
  string => 'I Love Logs! %msg%\n'
}

rsyslog::rule::remote { 'upstream':
  # Send Everything
  rule     => 'prifilt(\'*.*\')',
  # Use the 'upstream' template defined above
  template => 'upstream',
  # The Upstream Destination Server
  dest     => ['upstream.fq.dn'],
  require  => Rsyslog::Template::String['upstream']
}
```

### Mixed TLS and plain-text forwarding

`rsyslog::enable_tls_logging` sets whether remote rules use TLS by default.
Set `use_tls` on an `rsyslog::rule::remote` to override it for that rule:

**Puppet Code:**
```puppet
# With rsyslog::enable_tls_logging: true
rsyslog::rule::remote { 'legacy_collector':
  rule    => 'prifilt(\'*.*\')',
  dest    => ['legacy.collector.fq.dn'],
  use_tls => false,
}
```

`use_tls => true` forwards one rule over TLS on a host where
`enable_tls_logging` is `false`. It needs the TLS certificates, either copied
by `rsyslog::pki` or staged at the paths in `rsyslog::config`. UDP destinations
never use TLS.

## Reference

Please refer to the [REFERENCE.md](./REFERENCE.md).

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

By default, `pupmod-simp-rsyslog` tries to do the right thing during a failover
scenario and make sure that logs are always stored no matter what the state of
the remote log server(s) is. Be careful if you opt out of the default queuing
strategy for failover as it may cause undesirable results such as lost logs.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).

[System Integrity Management Platform](https://simp-project.com)
