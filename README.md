#pupmod-simp-rsyslog

[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/rsyslog.svg)](https://forge.puppetlabs.com/simp/rsyslog)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/rsyslog.svg)](https://forge.puppetlabs.com/simp/rsyslog)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-rsyslog.svg)](https://travis-ci.org/simp/pupmod-simp-rsyslog)


#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Overview](#overview)
* [This is a SIMP module](#this-is-a-simp-module)
* [Module Description](#module-description)
* [Setup](#setup)
  * [What pupmod-simp-rsyslog affects](#what-pupmod-simp-rsyslog-affects)
  * [Setup Requirements](#setup-requirements)
  * [Beginning with pupmod-simp-rsyslog](#beginning-with-pupmod-simp-rsyslog)
* [Usage](#usage)
  * [I want standard remote logging on a client](#i-want-standard-remote-logging-on-a-client)
  * [I want to send everything to rsyslog from a client](#i-want-to-send-everything-to-rsyslog-from-a-client)
  * [I want to disable TLS/PKI/Logrotate](#i-want-to-disable-tlspkilogrotate)
  * [I want to set up an RSyslog Server](#i-want-to-set-up-an-rsyslog-server)
  * [I want to set up an Rsyslog Server without logrotate/pki/firewall/tcpwrappers](#i-want-to-set-up-an-rsyslog-server-without-logrotatepkifirewalltcpwrappers)
  * [Central Log Forwarding](#central-log-forwarding)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Overview

[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) configures
and manages RSyslog version 8 as built into either
[RHEL](http://www.redhat.com/en) or [CentOS](https://www.centos.org/) versions
7 and 8.

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
firewall rules, logging, SELinux, and TCPWrappers. All of these items are
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
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* /etc/rsyslog.conf
* /etc/rsyslog.simp.d

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
* TCPWrappers (configurable)
* SELinux (configurable)
* Logrotate (configurable)

Packages installed by
[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* rsyslog
* rsyslog-gnutls

### Setup Requirements

It is *strongly* recommended that the logging infrastructure be set up in a
resilient manner. Failover in RSyslog is tricky and choosing the wrong kind of
queuing with failover could mean losing logs. This module attempts to protect
you from that, but will allow you to change the queuing mechanism to meet your
local requirements.

### Beginning with pupmod-simp-rsyslog

Including ``rsyslog`` will install, configure, and start the rsyslog daemon on a
client:

**Puppet Code:**
```puppet
include rsyslog
```

Including ``rsyslog::server`` will additionally configure the system as an Rsyslog
server.

**Puppet Code:**
```puppet
include rsyslog::server
```

## Usage

*WARNING:* The version of rsyslog that is included with EL7 and EL8 systems is
*not* the final stable upstream release. In particular, TLS may only be enabled
or disabled *globally*, not per ruleset or action!

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

### I want to set up an Rsyslog Server without logrotate/pki/firewall/tcpwrappers

**Hiera Config:**
```yaml
  rsyslog::logrotate: false
  rsyslog::server::enable_firewall: false
  rsyslog::server::enable_selinux: false
  rsyslog::server::enable_tcpwrappers: false
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
