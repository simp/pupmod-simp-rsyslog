Summary: Rsyslog Puppet Module
Name: pupmod-rsyslog
Version: 4.1.0
Release: 13
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-concat >= 4.0.0-0
Requires: pupmod-functions >= 2.1.0-0
Requires: puppet >= 3.3.0
Requires: pupmod-stunnel >= 4.1.0-3
Requires: pupmod-logrotate >= 4.1.0-0
Requires: pupmod-tcpwrappers >= 2.1.0-0
Requires: pupmod-common >= 4.2.0-13
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-rsyslog-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure RSyslog >= 3.0 on your
systems.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/rsyslog

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/rsyslog
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/rsyslog

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/rsyslog

%files
%defattr(0640,root,puppet,0750)
%{prefix}/rsyslog

%post
#!/bin/sh

if [ -d %{prefix}/rsyslog/plugins ]; then
  /bin/mv %{prefix}/rsyslog/plugins %{prefix}/rsyslog/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-13
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-12
- Changed puppet-server requirement to puppet

* Sat Dec 06 2014 Chris Tessmer <chris.tessmer@onyxpoint.com - 4.1.0-11
- backported host_is_me protection from 4.0.X fixes

* Wed Nov 19 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-10
- This is a relatively large update to the rsyslog module that
  (hopefully) fixes the last vestiges of the issues seen with
  multi-server failover and native TLS encryption.
- The main change is that we no longer support using stunnel but,
  instead, rely on native Rsyslog encryption for all actions.
- Message throttling is now *off* by default. This is a site-specific
  need and we just can't guess correctly.

* Mon Nov 03 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-9
- The lastaction restart of rsyslog in logrotate was changed to use the
  'service' command for RHEL7 compatibility.

* Tue Oct 07 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-8
- Ensure that MainMsgQueueSize is always > 0
- Ensure that the number of threads is always > 0

* Mon Sep 29 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-7
- Changed MainMsgQueueOnlyWhenPreviousIsSuspended and
  MainMsgQueueFileDefaultTemplate to be applied to the ActionQueue.

* Tue Sep 02 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-6
- Updated all instances of ActionQueue to MainMsgQueue in the global
  configuration. This makes the global disk queueing work as expected.

* Tue Jun 24 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-5
- Changed all checksums to sha256 instead of md5 in an effort to enable FIPS.

* Fri May 16 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-4
- Removed all stock classes and corresponding spec tests so they can be ported to the simp module.

* Tue May 13 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Updated to support most queueing options as applied to the default
  action queue.

* Sun May 04 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Ensure that all managed rsyslog configurations are written to
  /etc/rsyslog.d/puppet_managed and that unmanaged rules are selectively purged.
- Added an rsyslog::stock class which properly multiplexes between the local
  and server stock classes.
- Updated spec tests

* Wed Apr 09 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-2
- Refactored manifests for puppet 3 and hiera compatibility.
- Added spec tests.

* Tue Apr 01 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Changed all calls to stunnel::stunnel_add to stunnel:add.
- Removed the default size in rsyslog::stock::log_server since it
  conflicts with the default weekly rotation.
- Updated the default log format to be the Rsyslog default.
- Discovered a bug when enabling SELinux on both the client and server and
  moved the port for the log client to handle the SELinux rules.
- Added an stunnel rule for rsyslog that listens on the registered syslog-tls
  port.
- Flipped the singleton defines over to classes.
- Ensure that Stunnel traffic listens on all interfaces by default.
- Disabled the listeners on the log_local stock class since it is unnecessary
  and was interfering with Logstash.
- Added the ability to modify the rate limiting settings in
  rsyslog::global.
- Moved the include statement in the global conf template to after the
  definition of the default message template so that items in
  rsyslog.d can use it directly.

* Thu Feb 20 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-0
- Moved log forwarder rule (stock/log_server/forward.pp) from /etc/rsyslog.conf
  to /etc/rsyslog.d/remote.conf

* Wed Feb 12 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Converted all string booleans to booleans
- Fixed all lint errors

* Thu Jan 02 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-13
- Ensure that only the cron.hourly logrotate script exists if using
  the stock::log_server class.

* Fri Nov 01 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-12
- Added support to the stock server class for audispd.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> - 4.0.0-11
- Updated all erb templates to properly scope variables.

* Thu Sep 19 2013 Nick Markowski <nmarkowski@keywcorp.com> - 4.0.0-10
- Allowed default syslog logrotate missingok

* Thu Jan 31 2013 Maintenance
4.0.0-9
- Created a Cucumber test to setup an rsyslog server from the rsyslog module.

* Wed Nov 28 2012 Maintenance
4.0.0-8
- Updated the global config to turn $PreserveFQDN on by default.

* Mon Oct 22 2012 Maintenance
4.0.0-7
- Added compat level for 5 by default.
- Updated the stock rules to dump slapd audit logs to their own file.

* Fri Aug 10 2012 Maintenance
4.0.0-6
- Update to set max open files ulimit to unlimited using the new init_ulimit
  type.
- Added some options to the stock server class to ensure that collected logs
  are reasonably rotated and stored.

* Tue Jul 24 2012 Maintenance
4.0.0-5
- Fix all instances of 'IPT:' instead of "IPT:"

* Wed Apr 11 2012 Maintenance
4.0.0-4
- Fixed bug regarding stunnel module.
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
4.0.0-3
- Updated to ensure that sudosh output goes to its own log file.
- Improved test stubs.

* Tue Jan 17 2012 Maintenance
4.0.0-2
- Added a rule to allow all syslog connections past tcpwrappers. I know this
  isn't least privilege, but it's already being checked in two different
  places.

* Fri Dec 23 2011 Maintenance
4.0.0-1
- Updated the spec file to not require a separate file list.
- Changed all instances of 'ipaddress' to 'primary_ipaddress'.

* Mon Nov 07 2011 Maintenance
4.0.0-0
- Fixed call to rsyslog restart for RHEL6.

* Mon Oct 10 2011 Maintenance
2.0.0-3
- Updated to put quotes around everything that need it in a comparison
  statement so that puppet > 2.5 doesn't explode with an undef error.

* Tue Mar 29 2011 Maintenance - 2.0.0-2
- The 'onlyif' statement in concat_build was fixed to properly use
  /usr/bin/test.
- Modified the rsyslog rules to take apache into account.

* Fri Feb 11 2011 Maintenance - 2.0.0-1
- Changed all instances of defined(Class['foo']) to defined('foo') per the
  directions from the Puppet mailing list.
- Removed 'daemon.log' references which will make logrotate stop trying to
  rotate it and fail.
- Updated rsyslog::stock::log_server iptables rule
- Updated to use concat_build and concat_fragment types

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release
- Renamed puppet logs

* Fri Oct 29 2010 Maintenance - 1.0-3
- Replaced redundant rules with '& ~' which should improve performance.
- Moved the remote rsyslog security log rule into an 'if' that ensures that it
  is only activated when proper.
- Changed the module to call add_conf since those are loaded before the rest of
  the drop rules. Puppetmaster logs will now again flow to the remote log
  server.

* Tue Oct 26 2010 Maintenance - 1.0-2
- Converting all spec files to check for directories prior to copy.

* Thu Aug 05 2010 Maintenance
1.0-1
- rsyslog::log_server::allow was missing a '$' on the rhs of the udpServerAddress.

* Thu Jun 10 2010 Maintenance
1.0-0
- Removed data going to daemon.log by default. It was redundant with /var/log/messages.
- Full configuration of the daemon via /etc/sysconfig is now possible. Compatibility mode defaults to '3'.
- Added a new default log format with the priority included. Also provide for
  the capability to choose from one of the built-in rsyslog templates.
- Moved rsyslog::log_local and rsyslog::log_server to rsyslog::stock::log_local
  and rsyslog::stock::log_server respectively.
- Doc update and Code refactor.
- Fixed the default template by adding a '$' to the template entries.

* Wed May 12 2010 Maintenance
0.1-23
- Added a segment to remove the i386 version of rsyslog if you're on an
x86_64 system.

* Mon May 10 2010 Maintenance
0.1-22
- Now split puppet/puppetmaster logs into their own files on both the server
  and the client

* Tue Apr 27 2010 Maintenance
0.1-21
- Made the system require rsyslog.$architecture instead of rsyslog
- Fixed a bug in the rsyslog::server::allow define that would not let you
  properly set the udpServerAddress. It is now set to '0.0.0.0' by default.

* Wed Mar 17 2010 Maintenance
0.1-20
- Fixed a bug in the default server ruleset that was using '*' instead of '*.*'.

* Thu Jan 14 2010 Maintenance
0.1-19
- Allow users to set the maximum number of open files when configuring the
  rsyslog globals.

* Wed Jan 06 2010 Maintenance
0.1-18
- Now fork off iptables logs to /var/log/iptables.log.
- Added a logrotate rule for rotating the iptables log file.

* Wed Dec 30 2009 Maintenance
0.1-17
- Fixed a bug that did not allow the proper raising of max TCP sessions in
  rsyslog.

* Tue Dec 15 2009 Maintenance
0.1-16
- Fixed a bug that resulted in the daemon.log file not being rotated.
- Now ensure that the rsyslog server default configuration actually listens on
  all external ports by default instead of binding to localhost.
- Log server class now properly checks for ":IPT" instead of " :IPT"
- Log server class now sets lastaction instead of postrotate

* Wed Nov 04 2009 Maintenance
0.1-15
- Now call the new logrotate module to set up the log rotation job.

* Tue Oct 08 2009 Maintenance
0.1-14
- Modified the default 'secure' configurations to use verify = 2 by default.

* Tue Oct 06 2009 Maintenance
0.1-13
- Added a 'fail safe' mode to rsyslog so that it will never get an empty config
  file.
- Added pupmod-stunnel as a requirement.
