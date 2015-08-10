#pupmod-simp-rsyslog [![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-rsyslog.svg)](https://travis-ci.org/simp/pupmod-simp-rsyslog) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - A Puppet module for managing RSyslog version 7 or later](#module-description)
3. [Setup - The basics of getting started with pupmod-simp-rsyslog](#setup)
    * [What pupmod-simp-rsyslog affects](#what-pupmod-simp-rsyslog-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with pupmod-simp-rsyslog](#beginning-with-pupmod-simp-rsyslog)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) configures and manages RSyslog versions 7 and newer for either [RHEL](http://www.redhat.com/en) or [CentOS](https://www.centos.org/) versions 6 and 7. It is designed to work with [Puppet](https://puppetlabs.com/) version 3.4 or newer.

## Module Description

This module follows the standard [PuppetLabs module style guide](https://puppetlabs.com/guides/style_guide.html) with some SIMP-specific configuration items included for managing auditing, firewall rules, logging, SELinux, and TCPWrappers. All of these items are configurable and can be turned on or off as needed for each user environment.

[pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) was designed to be as compatible with RSyslog v7-stable as possible, though the version that comes stock with RHEL or CentOS is slightly dated and as such legacy code still exists. Where possible, all legacy code is documented with the new configuration commented out to show how any updates going forward will look.

It is possible to use [pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog) on its own and configure all rules and settings as you like, but it is recommended that the [SIMP Rsyslog Profile](https://github.com/simp/pupmod-simp-simp/tree/master/manifests/rsyslog) be used if possible. By default, this profile will setup security relevant logging rules and manage server/client configurations.

## Setup

### What pupmod-simp-rsyslog affects

Files managed by [pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* /etc/rsyslog.conf
* /etc/rsyslog.simp.d

In addition to these, the rsyslog::rule::<all> definitions will create numbered directories in the $rsyslog_rule_dir, by default /etc/rsyslog.simp.d. These directories are included in alphanumeric order and using the rsyslog::rule definition, the user can specify any directory name they want to impact order.

Services and operations managed or affected by [pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* rsyslogd
* auditd (configurable)
* iptables (configurable)
* TCPWrappers (configurable)
* SELinux (configurable)
* Logrotate (configurable)

Packages installed by [pupmod-simp-rsyslog](https://github.com/simp/pupmod-simp-rsyslog):
* rsyslog
* rsyslog-gnutls

### Setup Requirements

It is *strongly* recommended that any log server be setup as highly available as possible. Failover in RSyslog is tricky and choosing the wrong kind of queueing with failover could mean losing logs.

### Beginning with pupmod-simp-rsyslog

The very basic steps needed for a user to get the module up and running.

Including the [rsyslog class](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/init.pp) from pupmod-simp-rsyslog will be enough to [install](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/install.pp), [configure](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/config.pp), and start the [rsyslog daemon](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/service.pp) on any host. Including the [rsyslog::server](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/server.pp) class will setup the given node as an RSyslog server. If a particular node will be an RSyslog server, there are variables to determine if the RSyslog listener should use plain TCP, TLS, or UDP. 

*NOTE:* This version of (pupmod-simp-rsyslog)[https://github.com/simp/pupmod-simp-rsyslog] is a complete re-write of the previous version, and as such there are no guarantees made about backwards compatibility.

## Usage

pupmod-simp-rsyslog is meant to be extremely customizable, and as such there is no single best way to use it. For the SIMP specific recommendations on how to use RSyslog (and other modules as well), check out the [SIMP profile](https://github.com/simp/pupmod-simp-simp).

An example of an RSyslog client configuration may look like the following, including possible file names and a simple remote rule to forward all logs on the system.

my_client_node.yaml
```
log_servers:
  - first.log.server
  - second.log.server
  - third.log.server
  - fourth.log.server
rsyslog::enable_tls: true
rsyslog::allow_failover: true
rsyslog::enable_logging: true
rsyslog::enable_pki: true
```

my_rsyslog_client.pp
```
class my_rsyslog_client {
  include '::rsyslog'

  rsyslog::rule::remote { 'send_the_logs':
    $rule => '*.*'
  }
}
```

For the RSyslog server, an example setup could look like the following:

my_client_node.yaml
```
rsyslog::enable_tls: true
rsyslog::enable_logging: true
rsyslog::enable_pki: true
rsyslog::server::enable_firewall: true
rsyslog::server::enable_selinux: true
rsyslog::server::enable_tcpwrappers: true
```

my_rsyslog_server.pp
```
class my_rsyslog_server {
  include '::rsyslog'
  include '::rsyslog::server'

  rsyslog::template::string { 'store_the_logs':
    $content => '/var/log/hosts/%HOSTNAME%/everything.log'
  }
}
```

Using the above, all possible logs sent from the client will be stored on the server in a single log file. Obviously this is not always an effective strategy, but it is at least enough to get started. Further customizations can be built to help manage more logs appropriately. To learn more about how to use the templates and rules, feel free to browse through the code.

## Reference

Classes for pupmod-simp-rsyslog:
* [rsyslog](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/init.pp)
* [rsyslog::params](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/params.pp)
* [rsyslog::install](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/install.pp)
* [rsyslog::config](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/config.pp)
* [rsyslog::config::logging](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/config/logging.pp)
* [rsyslog::config::pki](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/config/pki.pp)
* [rsyslog::service](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/service.pp)
* [rsyslog::server](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/server.pp)
* [rsyslog::server::firewall](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/server/firewall.pp)
* [rsyslog::server::selinux](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/server/selinux.pp)
* [rsyslog::server::tcpwrappers](https://github.com/simp/pupmod-simp-rsyslog/tree/master/manifests/server/tcpwrappers.pp)

Defines for pupmod-simp-rsyslog:
* [rsyslog::rule::console](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/rule/console.pp)
* [rsyslog::rule::drop](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/rule/drop.pp)
* [rsyslog::rule::local](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/rule/local.pp)
* [rsyslog::rule::other](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/rule/other.pp)
* [rsyslog::rule::remote](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/rule/remote.pp)
* [rsyslog::template::list](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/template/list.pp)
* [rsyslog::template::plugin](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/template/plugin.pp)
* [rsyslog::template::string](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/template/string.pp)
* [rsyslog::template::subtree](https://github.com/simp/pupmod-simp-rsyslog/tree/manifests/template/subtree.pp)

## Limitations

This module is only designed to work in RHEL or CentOS 6 and 7. Any other operating systems have not been tested and results cannot be guaranteed.

Failover is tricky. By default, pupmod-simp-rsyslog tries to do the right thing and make sure that logs are always stored no matter what the state of the remote log server(s) is. Be careful if you opt out of the default queueing strategy for failover as it may cause undesirable results such as lost logs.

## Development

Please see the [SIMP Contribution Guidelines](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP).
General developer documentation can be found on [Confluence](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).
Visit the project homepage on [GitHub](https://github.com/NationalSecurityAgency/SIMP), chat with us on our [HipChat](https://simp-project.hipchat.com/), and look at our issues on  [JIRA](https://simp-project.atlassian.net/).
