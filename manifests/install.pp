# == Class: rsyslog::install
#
# Installs the RSyslog packages necessary for use of RSyslog.
#
class rsyslog::install {
  assert_private()

  $full_rsyslog_package = "${::rsyslog::package_name}.${::hardwaremodel}"

  package { $full_rsyslog_package: ensure => 'latest' }

  # remove existing/conflicting packages
  if $::rsyslog::package_name == 'rsyslog7' {
    package { "rsyslog.${::hardwaremodel}":
      ensure            => 'absent',
      uninstall_options => ['--nodeps'],
      provider          => 'rpm',
    }
    ->
    Package[$full_rsyslog_package]
  }


  # Some hackery to remove the i386 version of rsyslog if you're on a x86_64
  # system.
  if $::hardwaremodel == 'x86_64' {
    package { "${::rsyslog::package_name}.i386": ensure => 'absent' }
    ->
    Package[$full_rsyslog_package]
  }

  if ( $::rsyslog::enable_tls_logging or $::rsyslog::tls_tcp_server ) {
    Package[$full_rsyslog_package]
    ->
    package { $::rsyslog::tls_package_name: ensure => 'latest', }
  }
}
