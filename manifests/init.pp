# == Class: rsyslog
#
# Set up rsyslogd
#
# It is assumed that local6 will be used for all logs collected from files.
#
# You will need to add a rule specifically for this if you want to send them to
# a remote host.
#
# == Parameters
#
# [*purge_old_rules*]
# Type: Boolean
# Default: true
#   If true, remove all unmanaged rules in /etc/rsyslog.d/puppet_managed.
#
# [*enable_default_rules*]
# Type: Boolean
# Default: true
#   If true, add a set of reasonable output rules to the system targeted at
#   local files.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class rsyslog (
  $purge_old_rules = true,
  $enable_default_rules = true
){
  include 'logrotate'

  $outfile = concat_output('rsyslog')

  concat_build { 'rsyslog':
    order            => [ 'global', '*.template', '*.rule'],
    clean_whitespace => leading,
    target           => '/etc/rsyslog.conf',
    onlyif           =>
      "/usr/bin/test `/usr/bin/wc -w  ${outfile} | /bin/cut -f1 -d' '` -ne 0",
    require          => Package["rsyslog.${::hardwaremodel}"]
  }

  if $enable_default_rules {
    rsyslog::add_rule { 'ZZ_default':
      rule => template('rsyslog/rsyslog.default.erb')
    }
  }

  file { '/etc/rsyslog.conf':
    ensure    => 'present',
    owner     => 'root',
    group     => 'root',
    mode      => '0600',
    audit     => content,
    notify    => Service['rsyslog'],
    require   => Package["rsyslog.${::hardwaremodel}"],
    subscribe => Concat_build['rsyslog']
  }

  file { '/etc/rsyslog.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  file { '/etc/rsyslog.d/00_puppet_managed_include.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => "\$IncludeConfig /etc/rsyslog.d/puppet_managed/*.conf\n"
  }

  # This is where the custom rules will go. They will be purged if not
  # managed!
  file { '/etc/rsyslog.d/puppet_managed':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    recurse => $purge_old_rules,
    purge   => $purge_old_rules,
    notify  => Concat_build['rsyslog'],
    require => Package["rsyslog.$::hardwaremodel"]
  }

  file { '/etc/rsyslog.d/README.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content =>
      "# Place .conf files that rsyslog should process into this directory.\n",
    require => Package["rsyslog.$::hardwaremodel"]
  }

  file { '/var/spool/rsyslog':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => Package["rsyslog.$::hardwaremodel"]
  }

  # Set up the initial logrotate rule
  logrotate::add { 'syslog':
    log_files  => [
      '/var/log/messages',
      '/var/log/secure',
      '/var/log/maillog',
      '/var/log/spooler',
      '/var/log/boot.log',
      '/var/log/cron',
      '/var/log/iptables.log',
      '/var/log/puppet*.log'
    ],
    lastaction => '/sbin/service rsyslog restart > /dev/null 2>&1 || true',
    missingok  => true
  }

  package { "rsyslog.${::hardwaremodel}": ensure => 'latest' }

  # Some hackery to remove the i386 version of rsyslog if you're on a x86_64
  # system.
  if $::hardwaremodel == 'x86_64' {
    package { 'rsyslog.i386':
      ensure => 'absent',
      notify => Package["rsyslog.$::hardwaremodel"]
    }
  }

  service { 'rsyslog':
    ensure     => 'running',
    enable     => true,
    binary     => '/usr/bin/rsyslog',
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File['/etc/rsyslog.conf'],
      Package["rsyslog.$::hardwaremodel"]
    ]
  }

  validate_bool($purge_old_rules)
}
