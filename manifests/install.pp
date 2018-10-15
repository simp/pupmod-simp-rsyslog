# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Installs the packages necessary for use of RSyslog
#
# @param ensure
#   How to install the packages
#
#   * Accepts the same values as the ``Package`` resource's ``ensure``
#     parameter
#
class rsyslog::install (
  String $ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {
  assert_private()

  $_full_rsyslog_package = "${::rsyslog::package_name}.${facts['hardwaremodel']}"

  package { $_full_rsyslog_package:
    ensure => $ensure
  }

  # remove existing/conflicting packages
  if $::rsyslog::package_name == 'rsyslog7' {
    package { "rsyslog.${facts['hardwaremodel']}":
      ensure            => 'absent',
      uninstall_options => ['--nodeps'],
      provider          => 'rpm',
      before            => Package[$_full_rsyslog_package]
    }
  }

  # Some hackery to remove the i386 version of rsyslog if you're on a x86_64
  # system.
  if $facts['hardwaremodel'] == 'x86_64' {
    package { "${::rsyslog::package_name}.i386":
      ensure => 'absent',
      before => Package[$_full_rsyslog_package]
    }
  }

  if ( $::rsyslog::enable_tls_logging or $::rsyslog::tls_tcp_server ) {
    package { $::rsyslog::tls_package_name:
      ensure  => $ensure,
      require => Package[$_full_rsyslog_package]
    }
  }
}
